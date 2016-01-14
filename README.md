# rex-ossec-base

## setup()
Will add the ossec-hids-agent package to the designated server(s). You must set an IP and not DNS within the passed parameter. 

## clean()
Will remove the ossec-hids-package


```
task "setup", make {

  Rex::Collectd::Base::setup(server="SE.RV.ER.IP");

};
```

```
task "clean", make {

  Rex::Collectd::Base::clean();

};
```


# ossec
You will need to set up the server ready to accept the connections from the server. This will be done with the following
```
/var/ossec/etc/ossec-authd 
```

Once running, then you can run the deployment to your machines, and watch the service (hopefully) connect, and the job's done. 
