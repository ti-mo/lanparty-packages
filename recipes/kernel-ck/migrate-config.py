import sys
import re
import fileinput

path_src_conf = 'config/'+sys.argv[1]
path_migration = 'config/migrations/'+sys.argv[2]
path_dst_conf = 'config/'+sys.argv[3]

dst_conf = open(path_dst_conf)

with open(path_migration) as migration:
    with open(path_dst_conf) as src_conf: # Fix
        for entry in migration:
            keyword, value = entry.split('=', 1)
            regexp = '^\#?\s?{}'.format(keyword)

            rrc = re.search(regexp, src_conf.readlines())

            if rrc is None:
                # Append
                print('No match')
            else:
                # Replace
                print('Match')


    # Apply migrations to vanilla config

    # Write new config
