-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Keep G32P 3.5 mm audio on the HDMI pin for the live USB-C/DP connector.
o.launch_on_start("kuycon-dp-audio --watch")
