dreamail-proto
==============

This code was created in 2010 as a demo/prototype of a secure P2P file transfer system (codename "DreaMail") with emphasis on large data sizes and security.
It is actually a working code I used to pitch the idea to various people at coffee shops.

The repo includes two separate RoR applications, "agent" (aka user client) and "master" (aka tracker). It also includes a custom scripts directory that is used to help spawn multiple agent nodes with different configurations (port numbers, user names, etc.) on a single machine in a painless way, off the common code base.

The "socketry" library is shared across both application.

The client part of the agent app uses a few opensource libraries; I hope I did not violate anyone's copyright by including them in the code. Let me know if I did and I will gladly remove your library.

Hope someone will find this useful. Feel free to ask questions.
