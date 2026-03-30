sudo apt update

sudo apt purge -y \
    thunderbird \
    libreoffice* \
    rhythmbox \
    totem \
    transmission* \
    aisleriot \
    gnome-mahjongg \
    gnome-mines \
    gnome-sudoku \
    cheese \
    simple-scan \
    shotwell \
    remmina \
    yelp

sudo apt autoremove -y
sudo apt autoclean

snap list
sudo snap remove firefox
sudo snap remove snap-store
sudo snap remove thunderbird

sudo apt purge -y \
    gnome-clocks \
    gnome-characters \
    gnome-logs \
    gnome-disk-utility \
    evince \
    baobab

sudo apt autoremove -y