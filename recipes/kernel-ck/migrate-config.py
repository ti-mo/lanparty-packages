import sys
import re
from datetime import datetime

path_src_conf = 'config/'+sys.argv[1]
path_migration = 'config/migrations/'+sys.argv[2]
path_dst_conf = 'config/'+sys.argv[3]

dst_conf = open(path_dst_conf, "w+")

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

    print('\nMigration Hits:\n%s' % migration_hits)
    print('\nChanges:\n%s' % changes)
