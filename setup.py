from setuptools import setup, find_packages


setup(
    name="myapp",
    packages=find_packages('src'),
    package_dir={'': 'src'},
    entry_points='''
    [console_scripts]
    myapp=myapp.cli:myapp
    '''
)
