from setuptools import setup, find_packages

setup(
    name='bricklayer',
    version='1.0',
    packages=find_packages(), 
    data_files=[('/etc/bricklayer/',['config/bricklayer.ini'])],
    entry_points = {
        'console_scripts': [
            'bricklayerd = bricklayer.main.main_function',
        ]
    },
)
