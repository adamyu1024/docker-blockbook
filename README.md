## Stopping gracefully

To stop the container gracefully (and have the database files preserved), do a ```docker stop -t 60 blockbook``` and to restart it later, ```docker start blockbook```.

## Custom launcher

When using the command above to launch, the docker container will automatically generate the config file and will use sensible parameters to run Blockbook with Bitcoin.
If more control is desired, like using custom flags, custom configuration files, or using any shitcoin supported by Blockbook, just override the entrypoint:


```
 docker run -v /mnt/hgfs/workspace/blockbook-docker:/home/blockbook/cfg 
-w=/home/blockbook/go/src/blockbook -it -p 9136:9136 -p 9036:9036 
--entrypoint=/home/blockbook/go/src/blockbook/blockbook blockbook -sync -blockchaincfg=/home/blockbook/cfg/cfg.json 
-workers=1 -dbcache=0 -internal=:9036 -public=:9136 -logtostderr
```

The command above will run blockbook with 10 workers, using a custom configuration file called cfg.json, which will come from a volume mapping the local folder cfg to /home/blockbook/cfg inside the container. 
