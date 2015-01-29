TrinLoad 1.0
------------

TrinLoad is a network code loader for the SAM Coupe, accepting and executing
code and data sent to it from the network. It requires a Quazar Trinity
interface, since SAM lacks native ethernet hardware.

The server listens for requests on UDP port 0xEDB0. The first byte of each
request is the request type, and may be followed by additional parameters and
data.

The following requests are currently supported:

  ? = network discovery
  @ = data block
  X = execute

The network discovery request (?) is usually performed as a broadcast, to find
TrinLoad devices on the local subnet. Listening devices will respond with '!'.
Later versions may expand the payload to contain additional hardware details.

The data block request (@) should be followed by a SAM RAM page number, then a
16-bit offset (little-endian), and finally the data itself. TrinLoad will write
the payload to the given page and offset in RAM. Fragmented UDP datagrams are
not supported, so no more than 1468 bytes can be sent in each request. TrinLoad
will acknowledge the received block with '@' byte.

The execute request (X) should be followed by a RAM page number for HMPR, then
a 16-bit execution address. TrinLoad will acknowledge the block with 'X' before
beginning execution.

Additional block types will be added in future versions. See the included test
program for sample use.

---

Version 1.0 (2014/11/16)
- initial release

---

Simon Owen
http://simonowen.com/sam/trinload/
