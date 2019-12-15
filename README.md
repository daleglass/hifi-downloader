# hifi-downloader

Tool for mass downloading of HiFi assets, before doomsday comes.

High Fidelity is shutting down access on Janaury 15, 2020, and probably taking down all their assets with it. This tool is intended to be used to backup whatever might be needed for building the code and continuing development.

Use with care. It's likely that everything that can be downloaded should be.


# Usage


## Install dependencies (Fedora)

    dnf install perl-URI-Find perl-File-Slurp perl-File-Find
    
## Install dependencies (Ubuntu)

    apt install liburi-find-perl libfile-slurp-perl 

## Download files used by cmake into the current directory:

    ./downloader --scan-everything --url_filter=cmake --download ~/git/hifi

## Download all hifi related assets

**Warning**: This will download somewhere around 9 GB, and may include things not intended for redistribution. It will try to exclude things that are obviously not intended to be downloaded, but still might grab too much.

    ./downloader --scan-everything --url_filter=hifi --download ~/git/hifi

## Get a list of all URLs from the repository:

    ./downloader --scan-everything ~/git/hifi

