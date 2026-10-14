#!/bin/bash
. func.sh

create_thin_clone "client-1" "52:54:00:aa:bb:02" "/tmp/client1-userdata"
create_thin_clone "client-2" "52:54:00:aa:bb:03" "/tmp/client2-userdata"
