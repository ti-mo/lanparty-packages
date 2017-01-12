import argparse
import sys
import re
import os.path
from datetime import datetime

parser = argparse.ArgumentParser(description='Manipulate Kconfig files. '
    'Takes an upstream kernel configuration and applies a migration (changeset). '
    'All file arguments must be present in their respective relative directories:'
    'config/source/ - holds source configurations taken from eg. (source) packages '
    'config/migrations/ - migration files, read the README.md in this directory '
    'config/output/ - output directory for migrated configurations')

parser.add_argument('-v', '--verbose', action='store_true')
parser.add_argument('-n', '--nodiff', action='store_true')
parser.add_argument('source_config', help='The source configuration to migrate. '
    'The file given in this argument must be placed in config/source/')
parser.add_argument('migration', help='The migration to apply to the source config. '
    'Needs to be present in the relative config/migrations/ directory')
parser.add_argument('dest_config', help='The filename of the destination config. '
    'Will be written to config/output/.')

args = vars(parser.parse_args())

if args['verbose']: print(args)

path_src_conf = 'config/source/{}'.format(args['source_config'])
path_migration = 'config/migrations/{}'.format(args['migration'])
path_output_dir = 'config/output/'
path_dst_conf = '{}{}'.format(path_output_dir, args['dest_config'])

"""
Miniclass to hold the diff information for a key
:param line: the line number (in the source file) where the change is to be made
:param key: the name of the key
:param oldval: the value of the key in the source file
:param val: new value of the key in the destination file
"""
class DiffAction:
    def __init__(self, line, k, old, v):
        self.line, self.key, self.oldval, self.val = line, k, old, v

    def __repr__(self):
        return '{}: "{}" -> "{}" line {}'.format(self.key, self.oldval, self.val, self.line)

    def __str__(self):
        if self.val == 'n' or self.val == 'y':
            return '{}={}'.format(self.key, self.val)
        elif self.val == 'unset':
            return '# {} is not set'.format(self.key)
        else:
            return '{}="{}"'.format(self.key, self.val)

"""
Parse Kconfig lines into tuples
:param line: the Kconfig line to parse
:return: k, v tuple; both None on comment/empty line
"""
def parse_kconfig_line(line):
    # Check for lines to skip (comments and empty lines)
    if re.match('^\#', line):
        # Find unset values
        unset = re.match('^\#\s(.*)\sis\snot\sset', line)
        if unset is not None:
            k, v = unset.group(1), 'unset'
            return k, v
        else:
            return None, None
    elif not line.strip():
        return None, None
    else:
        k, v = line.split('=', 1)

        # Strip double quotes
        if v.startswith('"') and v.endswith('"'):
            v = v[1:-1]

        return k, v

"""
Parse migration into a dict
:param migration_cts: the migration file in string format
:return: dict containing migration k/v pairs
"""
def parse_migration(migration_cts):

    migration = {}

    # Duplicate migration entries will overwrite each other in order
    for entry in migration_cts.splitlines():
        # Skip comments
        if re.match('^\#', entry):
            continue

        k, v = entry.split('=', 1)

        # Strip double quotes
        if v.startswith('"') and v.endswith('"'):
            v = v[1:-1]

        migration[k] = v

    return migration

"""
Get k/v pairs that need to be added to the output configuration
:param migration: parsed migration dict
:param migration_hits: dict containing the migration keys with bool values
:return: a hash
"""
def get_additions(migration, migration_hits):
    # Get list of DiffActions that need to be added
    return {DiffAction(0, k, '', migration[k]) for k in migration if migration_hits[k] == False}

def render_additions(additions):
    out = ('#\n'
           '# Added from migration {} at {}\n'
           '#\n').format(sys.argv[2], datetime.now().isoformat())

    for a in additions:
        out += '{}\n'.format(str(a))

    out += '\n'

    return out

"""
Iterates over the given input file (string) line by line
and checks the given changeset for necessary changes.
:param config: the source Kconfig in string format
:param changes: a set of DiffActions to apply to the Kconfig
:return: the output string with the DiffActions applied
"""
def render_changes(config, changes):
    out = ""

    for i, line in enumerate(config.splitlines(), 1):
        if i in changes:
            out += '{}\n'.format(str(changes[i]))
        else:
            out += '{}\n'.format(line)

    return out

"""
Generate a changeset for the migration against the given source
This mutates migration_hits when keys in the migration are found in the file
:return: changeset, a dict {line_nr: DiffAction}
"""
def generate_changes(config, migration, migration_hits):

    # Start with empty changeset
    changes = {}

    # Read loop
    for i, line in enumerate(config.splitlines(), 1):
        k, v = parse_kconfig_line(line)

        # Skip this line if it's a comment or empty
        if k is None:
            continue

        # Check for values to modify in the configuration
        if k in migration:
            # Register a hit on this key, it was found in the configuration
            migration_hits[k] = True

            # Check if the value in the configuration differs
            if migration[k] != v:
                # Add an entry to the changes
                changes[i] = DiffAction(i, k, v, migration[k])

    return changes

"""
Print a list of changes to stdout
:param changeset: the changeset to print
:param mode: the character to append before every line
:return: None
"""
def print_diff(changeset, mode):
    for e in changeset:
        print('{} {}'.format(mode, e))

if not os.path.exists(path_src_conf):
    print('Source configuration {} not found, exiting.'.format(path_src_conf))
    sys.exit(1)

if not os.path.exists(path_migration):
    print('Migration {} not found, exiting.'.format(path_migration))
    sys.exit(1)

if not os.path.exists(path_output_dir):
    print('{} not found, creating directory.'.format(path_output_dir))
    os.mkdir(path_output_dir)

with open(path_migration) as migration_file, \
     open(path_src_conf) as src_conf_file, \
     open(path_dst_conf, 'w') as dst_conf_file:

    # Save contents to vars, but keep files open
    migration_cts = migration_file.read()
    src_conf_cts = src_conf_file.read()

    # Parse migration file
    migration = parse_migration(migration_cts)

    # Generate a dictionary to track which keys have generated a DiffAction
    # This works like a sort of refcount register; it mirrors the keys of the
    # migration dict, with bools as values. When a key is found in the source
    # configuration, its value is flipped to True
    migration_hits = {k: False for k in migration}

    print('Migration:\n%s' % migration)

    changes = generate_changes(src_conf_cts, migration, migration_hits)

    # Determine lines that are to be added by comparing
    # the hit register against the migration
    additions = get_additions(migration, migration_hits)

    # Write additions (in the header)
    dst_conf_file.write(render_additions(additions))

    # Write the body of the destination configuration
    dst_conf_file.write(render_changes(src_conf_cts, changes))

    if not args['nodiff']:
        print('Results:')
        print_diff(additions, '+')
        print()
        print_diff({changes[x] for x in changes}, '~')
