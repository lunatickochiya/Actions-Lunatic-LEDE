 #!/bin/bash
for file in *.config
do
echo "CONFIG_PACKAGE_luci-app-control-weburl=y" >> $file
echo "CONFIG_PACKAGE_luci-app-fileassistant=y" >> $file
done