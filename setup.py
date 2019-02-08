import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
        name="pfocr",
        version="1.0.0",
        description="Information extractor for figures in biology research papers",
        long_description=long_description,
        long_description_content_type="text/markdown",
        author="Anders Riutta",
        author_email="anders.riutta+pfocr@gladstone.ucsf.edu",
        url="https://github.com/wikipathways/pathway-figure-ocr",
        packages=setuptools.find_packages(),
        license="Apache License 2.0",
        install_requires=[
            "dill",
            "idna",
            "pygpgme",
            "psycopg2",
            "requests",
            "Wand",
            "confusable-homoglyphs>=3.2.0",
            "homoglyphs>=1.3.2",
            "bs4"
            ],
        # TODO: should we have a __main__.py?
        entry_points={
            'console_scripts': [
                'pfocr=pfocr:main'
                ]
            },
        classifiers=[
            "Programming Language :: Python :: 3",
            "Development Status :: 4 - Beta",
            "Intended Audience :: Science/Research",
            "Intended Audience :: Developers",
            "Topic :: Scientific/Engineering :: Bio-Informatics",
            "Topic :: Software Development :: Libraries :: Python Modules",
            "License :: OSI Approved :: Apache Software License",
            ],
        )
