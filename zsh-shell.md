# ZSH Terminal

### How to Install ZSH (Z Shell) on Ubuntu 20.04

The Zsh (Z shell) is a interactive login shell for the Unix/Linux systems. It has multiple improvement over the Bash shell and includes the best features of the Bash, ksh and tcsh shells. This tutorial will help you to install ZSH on Ubuntu 20.04 LTS Linux system.

### Installing ZSH on Ubuntu

Zsh packages are available under the default apt repositories. So first, update the Apt cache on your system with latest available packages.

```
sudo apt update 
```

Then type below command to install zsh shell packages with required dependencies.

```
sudo apt install zsh
```

[![Installing ZSH on Ubuntu 20.04](https://tecadmin.net/wp-content/uploads/2020/08/installing-zsh-on-ubuntu-20-04.png)](https://tecadmin.net/wp-content/uploads/2020/08/installing-zsh-on-ubuntu-20-04.png)

Once the installation completed, let’s check the installed Zsh shell version by running command:

```
zsh --version
```

[![Check ZSH Shell Version on Ubuntu 20.04](https://tecadmin.net/wp-content/uploads/2020/08/check-zsh-version-ubuntu-20-04.png)](https://tecadmin.net/wp-content/uploads/2020/08/check-zsh-version-ubuntu-20-04.png)

## Installing Oh-My-Zsh Plugin

[On-My-Zsh](https://github.com/robbyrussell/oh-my-zsh/)  plugin provides a large number of customization for the Z shell. So without this plugion Zsh plugin is incomplete. So we also recommend to install this plugin on with Zsh shell.

```
sudo apt install git-core curl fonts-powerline 
```

Oh-My-Zsh provides a shell script for the installation on Linux systems. Execute the following command to install this plugion on your system.

```
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" 
```

This will ask you to setup Zsh as default set. You can access or reject this as your choice. After that installation will complete within few seconds.

You may like to change Zsh theme by editiog ~/.zshrc file on your system. You can select a theme from  [here](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes).

```
sudo vi ~/.zshrc 
```

Set theme name to ZSH_THEME environment variable.

Shell
```
Set name of the theme to load --- if set to "random", it will
load a random theme each time oh-my-zsh is loaded, in which case,
to know which specific one was loaded, run: echo $RANDOM_THEME
See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

ZSH_THEME="agnoster"
```

Save file and close it. Then launch a new shell to apply changes.

## Launch Zsh Shell Terminal

To launch a Zsh shell terminal just type “zsh” from your current shell.

```
zsh 
```

[![Start a new Z shell terminal](https://tecadmin.net/wp-content/uploads/2020/08/start-zsh-on-ubuntu.png)](https://tecadmin.net/wp-content/uploads/2020/08/start-zsh-on-ubuntu.png)

## Conclusion

In this tutorial, you have learned about installation off Zsh shell on Ubuntu system. Also installed Oh-My-Zsh plugin on your system.
