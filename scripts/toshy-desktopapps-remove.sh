#!/usr/bin/env bash


# Remove the Toshy desktop entry files so that app launchers and menus do not
# "see" them anymore. 

# Check if the script is being run as root
if [[ $EUID -eq 0 ]]; then
    echo "This script must not be run as root"
    exit 1
fi

# Check if $USER and $HOME environment variables are not empty
if [[ -z $USER ]] || [[ -z $HOME ]]; then
    echo "\$USER and/or \$HOME environment variables are not set. We need them."
    exit 1
fi



echo -e "\nRemoving Toshy Preferences and Tray Icon app launchers..."

rm -f "$HOME/.local/share/applications/Toshy_GUI.desktop"
rm -f "$HOME/.local/share/applications/Toshy_Tray.desktop"
rm -f "$HOME/.local/share/icons/toshy_app_icon_rainbow.svg"

echo ""
echo "Finished removing Toshy Preferences and Tray Icon app launchers:"
echo ""
echo "- Toshy_GUI.desktop"
echo "- Toshy_Tray.desktop"
echo ""
