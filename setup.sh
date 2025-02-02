# # # Distribution Statement A. Approved for public release. Distribution unlimited.
# # #
# # # Author:
# # # Naval Research Laboratory, Marine Meteorology Division
# # #
# # # This program is free software: you can redistribute it and/or modify it under
# # # the terms of the NRLMMD License included with this program. This program is
# # # distributed WITHOUT ANY WARRANTY; without even the implied warranty of
# # # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the included license
# # # for more details. If you did not receive the license, for more information see:
# # # https://github.com/U-S-NRL-Marine-Meteorology-Division/

#!/bin/bash

date_cmd=date
if [[ $OSTYPE == 'darwin'* ]]; then
    date_cmd="$(which gdate)"
    if [[ $? -ne 0 ]]; then
        echo "On Mac, please install gdate. For example, brew install coreutils."
        exit 1
    fi
fi

if [[ -z "$GEOIPS_PACKAGES_DIR" ]]; then
    echo "Must define GEOIPS_PACKAGES_DIR environment variable prior to setting up geoips"
    exit 1
fi

# This sets required environment variables for setup - without requiring sourcing a geoips config in advance
. $GEOIPS_PACKAGES_DIR/geoips/setup/repo_clone_update_install.sh setup

if [[ ! -d $GEOIPS_DEPENDENCIES_DIR/bin ]]; then
    mkdir $GEOIPS_DEPENDENCIES_DIR/bin
fi
if [[ "$1" == "conda_install" ]]; then
    echo ""

    # echo "**wgetting Anaconda3*.sh"
    # wget https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh -P $GEOIPS_DEPENDENCIES_DIR
    # chmod 755 $GEOIPS_DEPENDENCIES_DIR/Anaconda3-*.sh

    opsys=Linux
    arch=$(uname -m)
    if [[ "$(uname -s)" == "Darwin" ]]; then
        opsys=MacOSX
    fi


    if [[ "$2" == "conda_defaults_channel" ]]; then
        echo "**wgetting Miniconda3*.sh"
        conda_fname=Miniconda3-latest-${opsys}-${arch}.sh
        echo "wget https://repo.anaconda.com/miniconda/${conda_fname} -P $GEOIPS_DEPENDENCIES_DIR"
        wget https://repo.anaconda.com/miniconda/${conda_fname} -P $GEOIPS_DEPENDENCIES_DIR
        wget_retval=$?
    else
        # echo "**wgetting Miniforge3*.sh"
        # conda_fname=Miniforge3-${opsys}-${arch}.sh
        echo "**wgetting Mambaforge*.sh"
        conda_fname=Mambaforge-${opsys}-${arch}.sh
        echo "wget https://github.com/conda-forge/miniforge/releases/latest/download/${conda_fname} -P $GEOIPS_DEPENDENCIES_DIR"
        wget https://github.com/conda-forge/miniforge/releases/latest/download/${conda_fname} -P $GEOIPS_DEPENDENCIES_DIR
        wget_retval=$?
    fi
    if [[ "$wget_retval" != "0" ]]; then
        echo "FAILED: wget of conda installer failed. Try again."
        exit 1
    fi

    chmod 755 $GEOIPS_DEPENDENCIES_DIR/${conda_fname}
    echo ""
    echo "**Running conda installer"
    echo "$GEOIPS_DEPENDENCIES_DIR/${conda_fname} -p $GEOIPS_DEPENDENCIES_DIR/miniconda3"
    $GEOIPS_DEPENDENCIES_DIR/${conda_fname} -p $GEOIPS_DEPENDENCIES_DIR/miniconda3
    conda_retval=$?
    if [[ "$conda_retval" != "0" ]]; then
        echo "FAILED: conda installer failed. Try again."
        exit 1
    fi

    echo "**Sourcing geoips_conda environment setup"
    echo "source $GEOIPS_PACKAGES_DIR/geoips/setup/geoips_conda_init_setup"
    source $GEOIPS_PACKAGES_DIR/geoips/setup/geoips_conda_init_setup
    setup_retval=$?
    if [[ "$setup_retval" != "0" ]]; then
        echo "FAILED: conda environment init failed. Try again."
        exit 1
    fi

    which_conda=`which conda`
    which_python=`which python`
    if [[ "$which_conda" == "" ]]; then
        echo "FAILED: No conda executable found.  Please attempt installation again"
        exit 1
    else
        echo "SUCCESS: conda installation successful: $which_conda"
    fi


elif [[ "$1" == "conda_init" ]]; then
    echo ""
    echo "**Initializing conda"
    conda init
    echo ""
    # echo "**IF SCRIPT WAS NOT SOURCED MUST source ~/.bashrc or restart shell"
    # source ~/.bashrc
    # echo "source ~/.bashrc"
    echo "**Sourcing geoips_conda environment setup"
    echo "source $GEOIPS_PACKAGES_DIR/geoips/setup/geoips_conda_init_setup"
    source $GEOIPS_PACKAGES_DIR/geoips/setup/geoips_conda_init_setup
    setup_retval=$?
    if [[ "$setup_retval" != "0" ]]; then
        echo "FAILED: conda environment init failed. Try again."
        exit 1
    fi
elif [[ "$1" == "conda_update" ]]; then
    echo ""
    echo "**updating base conda env"
    which conda
    which python
    # Use conda-forge by default
    if [[ "$2" == "conda_defaults_channel" ]]; then
        conda update -n base -c defaults conda --yes
    else
        conda update -n base -c conda-forge conda --yes
    fi
elif [[ "$1" == "remove_geoips_conda_env" ]]; then
    echo ""
    echo "**removing geoips_conda env"
    which conda
    which python
    echo "**IF SCRIPT WAS NOT SOURCED MUST first deactivate geoips_conda env from parent shell"
    conda deactivate
    echo "conda deactivate"
    conda env remove --name geoips_conda
elif [[ "$1" == "create_geoips_conda_env" ]]; then
    echo ""
    echo "**Sourcing geoips_conda environment setup"
    echo "source $GEOIPS_PACKAGES_DIR/geoips/setup/geoips_conda_init_setup"
    source $GEOIPS_PACKAGES_DIR/geoips/setup/geoips_conda_init_setup
    setup_retval=$?
    if [[ "$setup_retval" != "0" ]]; then
        echo "FAILED: conda environment init failed. Try again."
        exit 1
    fi

    which conda
    which mamba
    which python
    echo ""
    echo "**creating geoips_conda env"
    # Note: cartopy 0.21 is incompatible with geos 3.12.  Causes seg fault when
    # writing out certain imagery. Note other incompatibilities between various
    # older matplotlib and cartopy versions as well.
    # cartopy >= 0.22 no longer requires geos.
    # openblas/gcc required for recenter_tc / akima build.
    # gcc<10 required for seviri wavelet transform build
    # imagemagick required for image comparisons
    # git required for -C commands
    # rclone required for NOAA AWS ABI/AHI downloads
    if [[ "$2" == "conda_defaults_channel" ]]; then
        echo "conda create --yes --name geoips_conda -c defaults python=3.9 gcc gxx openblas git --yes"
        conda create --yes --name geoips_conda -c defaults python=3.9 gcc gxx openblas git --yes
        conda_retval=$?
    else
        echo "mamba create --yes --name geoips_conda -c conda-forge python=3.9 gcc gxx openblas git --yes"
        mamba create --yes --name geoips_conda -c conda-forge python=3.9 gcc gxx openblas git --yes
        conda_retval=$?
    fi
    if [[ "$conda_retval" != "0" ]]; then
        echo "FAILED: conda create failed. Try again."
        exit 1
    fi
    echo "**IF SCRIPT WAS NOT SOURCED MUST activate geoips_conda env from parent shell"
    conda activate geoips_conda
    echo "conda activate geoips_conda"
    which_conda=`which conda`
    which_python=`which python`
    if [[ "$which_conda" == "" ]]; then
        echo "FAILED: No conda executable found.  Please attempt installation again"
        exit 1
    else
        echo "SUCCESS: conda installation successful: $which_conda"
    fi
    if [[ "$which_python" != *"geoips_conda"* ]]; then
        echo "FAILED: python executable NOT in geoips_conda env: $which_python."
        echo "FAILED: Please attempt create_geoips_conda_env again."
        exit 1
    else
        echo "SUCCESS: geoips_conda installation successful: $which_python"
    fi

elif [[ "$1" == "install" ]]; then
    echo ""
    echo "**Installing geoips and all dependencies"
    echo "pip install -e "$GEOIPS_PACKAGES_DIR/geoips"[doc,test,lint,debug]"
    pip install -e "$GEOIPS_PACKAGES_DIR/geoips"[doc,test,lint,debug]
    pip_retval=$?
    if [[ "$pip_retval" != "0" ]]; then
        echo "FAILED: pip install failed. Try again."
        exit 1
    else
        echo "SUCCESS: pip installed geoips and dependencies successfully."
    fi

elif [[ "$1" == "setup_vim8" ]]; then
    mkdir -p $GEOIPS_DEPENDENCIES_DIR/vim8_build
    cwd=`pwd`
    cd $GEOIPS_DEPENDENCIES_DIR/vim8_build
    git clone https://github.com/vim/vim.git
    cd vim
    ./configure --prefix=${GEOIPS_DEPENDENCIES_DIR}/vim8_build/vim --disable-nls --enable-cscope --enable-gui=no --enable-multibyte --enable-pythoninterp --with-features=huge --with-tlib=ncurses --without-x;
    make
    make install
    mkdir -p $GEOIPS_DEPENDENCIES_DIR/bin
    ln -s $GEOIPS_DEPENDENCIES_DIR/vim8_build/vim/bin/vim $GEOIPS_DEPENDENCIES_DIR/bin/vi
    ln -s $GEOIPS_DEPENDENCIES_DIR/vim8_build/vim/bin/vim $GEOIPS_DEPENDENCIES_DIR/bin/vim
    cd $cwd
elif [[ "$1" == "setup_vim8_plugins" ]]; then
    mkdir -p $GEOIPS_DEPENDENCIES_DIR/vimdotdir/pack/plugins/start
    cwd=`pwd`
    cd $GEOIPS_DEPENDENCIES_DIR/vimdotdir/pack/plugins/start
    git clone https://github.com/w0rp/ale.git
    cd $cwd
    pip install flake8
    pip install pylint
    pip install bandit
    mkdir -p ~/.vim/pack
    ## If ~/.vim/pack does not exist, link it, otherwise link the contents appropriately.
    echo ""
    ln -sv $GEOIPS_DEPENDENCIES_DIR/vimdotdir/pack/* ~/.vim/pack
    if [[ $? != 0 ]]; then
        echo "If you want to replace ~/.vim/pack with geoips version, run the following:"
        echo "ln -sfv $GEOIPS_DEPENDENCIES_DIR/vimdotdir/pack/* ~/.vim/pack"
    fi
    echo ""
    ## Either add the contents of vimrc_ale to your ~/.vimrc, or replace it
    ln -sv $GEOIPS_PACKAGES_DIR/geoips/setup/bash_setup/vimrc_ale ~/.vimrc
    if [[ $? != 0 ]]; then
        echo "If you want to replace ~/.vimrc with geoips ALE version, run the following:"
        echo "ln -sfv $GEOIPS_PACKAGES_DIR/geoips/setup/bash_setup/vimrc_ale ~/.vimrc"
    fi
elif [[ "$1" == "download_cartopy_natural_earth" ]]; then
    echo ""
    echo "**Installing github.com/nvkelso/natural-earth-vector map data latest version, (last tested v5.2.0) this will take a while"
    cartopy_data=$GEOIPS_DEPENDENCIES_DIR/cartopy_map_data
    echo "    destination: $cartopy_data"
    mkdir -p $cartopy_data
    cwd=`pwd`
    cd $cartopy_data
    git clone https://github.com/nvkelso/natural-earth-vector
    cd natural-earth-vector
    git fetch --all --tags --prune
    # Previously 5.0.0, 20220607 5.2.0
    # echo "    **Checking out tag v5.2.0, to ensure tests pass"
    # git checkout tags/v5.2.0
    git tag | tail -n 5
    cat VERSION
    echo "Last tested version: v5.2.0"
    echo "If latest version is greater than v5.2.0, watch out for failed tests"
    cd $cwd
elif [[ "$1" == "link_cartopy_natural_earth" ]]; then
    echo ""
    source_cartopy_data=$GEOIPS_DEPENDENCIES_DIR/cartopy_map_data
    if [[ -z "$CARTOPY_DATA_DIR" ]]; then
        CARTOPY_DATA_DIR=$GEOIPS_DEPENDENCIES_DIR/CARTOPY_DATA_DIR
    fi
    linkdir=$CARTOPY_DATA_DIR/shapefiles/natural_earth
    echo "**Linking natural-earth-data from $source_cartopy_data to $CARTOPY_DATA_DIR/shapefiles/natural_earth/cultural and physical"
    mkdir -p $linkdir/cultural
    mkdir -p $linkdir/physical
    ln -sfv $source_cartopy_data/natural-earth-vector/*_cultural/*/* $linkdir/cultural
    ln1_retval=$?
    ln -sfv $source_cartopy_data/natural-earth-vector/*_physical/*/* $linkdir/physical
    ln2_retval=$?
    ln -sfv $source_cartopy_data/natural-earth-vector/*_cultural/* $linkdir/cultural
    ln3_retval=$?
    ln -sfv $source_cartopy_data/natural-earth-vector/*_physical/* $linkdir/physical
    ln4_retval=$?
    if [[ $ln1_retval != 0 || $ln2_retval != 0 || $ln3_retval != 0 || $ln4_retval != 0 ]]; then
        echo "**You MUST be able to replace ALL user cartopy data with natural_earth_vector downloads!"
        echo "Please remove cartopy shapefiles and replace with downloaded cartopy_map_data"
        echo "rm -fv ~/.local/share/cartopy/shapefiles/natural_earth/cultural/*"
        echo "rm -fv ~/.local/share/cartopy/shapefiles/natural_earth/physical/*"
        echo "ln -sfv $source_cartopy_data/natural-earth-vector/*_cultural/* $linkdir/cultural"
        echo "ln -sfv $source_cartopy_data/natural-earth-vector/*_physical/* $linkdir/physical"
        exit 1
    fi

# This appears to be unused
elif [[ "$1" =~ "install_geoips_plugin" ]]; then
    $0 clone_source_repo $2
    clone_retval=$?
    pip install -e $GEOIPS_PACKAGES_DIR/$2
    pip_retval=$?
    if [[ "$pip_retval" != "0" || "$clone_retval" != "0" ]]; then
        exit 1
    fi

# This is only used by repo_clone_update_install.sh which itself appears to be unused
elif [[ "$1" =~ "clone_source_repo" ]]; then
    echo ""
    echo "**Cloning $2.git"

    repo_name=$2
    repo_url=$GEOIPS_REPO_URL/$repo_name

    # If reponame of format "GEOIPS/geoips" then pull out org and reponame separately
    # "/geoips" would indicate top level (no sub-org)
    if [[ `echo "$2" | grep '/'` != "" ]]; then
        repo_org=`echo "$2" | cut -f 1 -d '/'`
        repo_name=`echo "$2" | cut -f 2 -d '/'`
        if [[ "$GEOIPS_BASE_URL" != "" ]]; then
            repo_url=$GEOIPS_BASE_URL/$repo_org/$repo_name
        else
            repo_url=`dirname $GEOIPS_REPO_URL`/$repo_org/$repo_name
        fi
    fi

    git clone $repo_url.git $GEOIPS_PACKAGES_DIR/$repo_name
    retval=$?
    echo "git clone return: $retval"
    if [[ $retval != 0 ]]; then
        echo "**You can ignore 'fatal: destination path already exists' - just means you already have the repo"
    fi
# This is only used by repo_clone_update_install.sh which itself appears to be unused
elif [[ "$1" =~ "update_source_repo" ]]; then
    if [[ "$3" == "" ]]; then
        branch=main
    else
        branch=$3
    fi
    if [[ "$4" == "do_not_fail" ]]; then
        do_not_fail="do_not_fail"
    else
        do_not_fail=""
    fi
    currdir=$GEOIPS_PACKAGES_DIR/$2
    echo ""
    echo "**Updating $2 branch $branch"
    cwd=`pwd`
    cd $GEOIPS_PACKAGES_DIR/$2
    git pull
    git checkout -t origin/$branch
    retval_t=$?
    git checkout $branch
    retval=$?
    git pull
    git pull
    cd $cwd
    retval_pull=$?
    echo "git checkout -t return: $retval_t"
    echo "git checkout return: $retval"
    echo "git pull return: $retval_pull"
    if [[ $retval != 0 || $retval_t != 0 ]]; then
        echo "**You can ignore 'fatal: A branch named <branch> already exists' - just means you already have the branch"
    fi
    if [[ $retval != 0 && $retval_t != 0 && "$do_not_fail" != "do_not_fail" ]]; then
        echo "*****GIT CHECKOUT FAILED ON $currdir $branch PLEASE APPROPRIATELY commit (if you want to save your changes), checkout (if you do not want to save changes of a git-tracked file), or delete (if you do not want to save changes of an untracked file) ANY LOCALLY MODIFIED FILES AND RERUN repo_update COMMAND. This will ensure you have the latest version of all repos!!!!!!!!"
        exit 1
    fi
    if [[ $retval_pull != 0 && "$do_not_fail" != "do_not_fail" ]]; then
        echo "*****GIT PULL FAILED ON $currdir $branch PLEASE APPROPRIATELY commit (if you want to save your changes), checkout (if you do not want to save changes of a git-tracked file), or delete (if you do not want to save changes of an untracked file) ANY LOCALLY MODIFIED FILES AND RERUN repo_update COMMAND. This will ensure you have the latest version of all repos!!!!!!!!"
        exit 1
    fi

# This is only used by repo_clone_update_install.sh which itself appears to be unused
elif [[ "$1" =~ "clone_external_repo" ]]; then
    echo ""
    echo "**Cloning external repo $2"
    if [[ "$2" == "archer" ]]; then
        git clone https://github.com/ajwimmers/archer $GEOIPS_PACKAGES_DIR/archer
        retval=$?
        echo "git clone return: $retval"
    else
        echo "Unknown external repo"
    fi
    if [[ $retval != 0 ]]; then
        echo "**You can ignore 'fatal: destination path already exists' - just means you already have the repo"
    fi

# This appears to be unused
elif [[ "$1" =~ "run_git_cmd" ]]; then
    gitbasedir=$GEOIPS_PACKAGES_DIR
    if [[ "$4" != "" ]]; then
        gitbasedir=$4
    fi
    echo ""
    echo "**Running cd $gitbasedir/$2; git $3"
    cwd=`pwd`
    cd $gitbasedir/$2
    git $3
    cd $cwd
    retval=$?
    echo "git $3 return: $retval"

# This is only used by repo_clone_update_install.sh which itself appears to be unused
elif [[ "$1" =~ "update_external_repo" ]]; then
    currdir=$GEOIPS_PACKAGES_DIR/$2
    if [[ "$3" == "do_not_fail" ]]; then
        do_not_fail="do_not_fail"
    else
        do_not_fail=""
    fi
    echo ""
    echo "**Updating external repo $2"
    cwd=`pwd`
    cd $GEOIPS_PACKAGES_DIR/$2
    git pull
    cd $cwd
    retval=$?
    echo "git pull return: $retval"
    if [[ $retval != 0 && "$do_not_fail" != "do_not_fail" ]]; then
        echo "*****GIT PULL FAILED ON $currdir PLEASE APPROPRIATELY commit (if you want to save your changes), checkout (if you do not want to save changes of a git-controlled file), or delete (if you do not want to save changes of a non-git-controlled file) ANY LOCALLY MODIFIED FILES AND RERUN repo_update COMMAND. This will ensure you have the latest version of all repos!!!!!!!!"
        exit 1
    fi
elif [[ "$1" =~ "install_plugin" ]]; then
    plugin=$2
    installed_plugins_path=$GEOIPS_PACKAGES_DIR/installed_geoips_plugins.txt
    echo ""
    echo "**Installing plugin $plugin"
    # Check if setup.sh exists
    # NOTE if setup.sh exists, MUST include "install" (which may just be
    # pip install -e .) in order for plugin package to install using
    # 'geoips/setup.sh install_plugin'.
    if [[ -f $GEOIPS_PACKAGES_DIR/$2/setup.sh ]]; then
        echo "**Found setup.sh: Running $2/setup.sh install"
        $GEOIPS_PACKAGES_DIR/$2/setup.sh install
        retval=$?
    # Next check if pyproject.toml exists
    elif [[ -f $GEOIPS_PACKAGES_DIR/$2/pyproject.toml ]]; then
        echo "**Found pyproject.toml: pip installing plugin $2"
        pip install -e $GEOIPS_PACKAGES_DIR/$2
        retval=$?
    # Next check if setup.py exists
    elif [[ -f $GEOIPS_PACKAGES_DIR/$2/setup.py ]]; then
        echo "**Found setup.py: pip installing plugin $2"
        pip install -e $GEOIPS_PACKAGES_DIR/$2
        retval=$?
    fi
    if [[ $retval != 0 ]]; then
        echo "**Failed installing plugin $2, skipping! Must include one of the following setup options:"
        echo "**1. setup.sh install (if setup.sh exists, MUST include 'install' command)"
        echo "**2. pyproject.toml -> Installed via 'pip install -e $GEOIPS_PACKAGES_DIR/$2"
        echo "**3. setup.py -> Installed via 'pip install -e $GEOIPS_PACKAGES_DIR/$2'"
    elif [[ -f $installed_plugins_path ]]; then
        echo ""
        echo "Adding plugin $plugin to list $installed_plugins_path, will not reinstall"
        echo "$plugin" >> $installed_plugins_path
    fi
    echo ""
else
    echo "UNRECOGNIZED COMMAND $1"
    exit 1
fi
exit 0
