from setuptools import setup, find_packages

setup(
    name='bricklayer',
    version='1.0',
    packages=find_packages(), 
    entry_points = {
        'console_scripts': [
            'bricklayer = main.main_function',
        ]
    },
)
