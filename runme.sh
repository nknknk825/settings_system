# install packet manager
git clone https://github.com/folke/lazy.nvim.git ~/.local/share/nvim/lazy/lazy.nvim
nvim --headless "+Lazy! sync" +qa

# Копируем бинарники в системные директории
sudo cp -r nvim-linux-x86_64/bin/* /usr/local/bin/
sudo cp -r nvim-linux-x86_64/lib/* /usr/local/lib/
sudo cp -r nvim-linux-x86_64/share/* /usr/local/share/

rm -rf nvim-linux-x86_64


printf 'export PATH="/usr/local/bin:$PATH"\n' > ~/.bashrc
source ~/.bashrc
