import os
from setuptools import setup, find_packages

template_dir = []
for root, dirs, files in os.walk('pkg_template'):
    if not dirs: 
        template_dir.append((os.path.join('/var/lib/bricklayer/', root), 
            map(lambda x: os.path.join(root, x), files))
        )

data_files_list = template_dir
data_files_list.extend([
        ('/etc/bricklayer/', ['config/bricklayer.ini']),
        ('/var/lib/bricklayer/', ['db/bricklayer.db']),
    ]
)
setup(
    name='bricklayer',
    version='1.0',
    packages=find_packages(), 
    data_files=data_files_list,
    entry_points = {
        'console_scripts': [
            'bricklayerd = bricklayer.main:main_function',
        ]
    },
)
