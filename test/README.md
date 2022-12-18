# trinload.py

`trinload.py` is an example network code loader that sends a test program to
TrinLoad running on a Sam coupé. It is written in Python 2.

The protocol used by `trinload.py` is explained in the parent directory
`ReadMe.txt` file.

The following is a detailed analysis of the Layer 2 Ethernet Frames which are
actually sent and received by the `trinload.py` test example.

## Layer 2 Ethernet Frames Sent And Received

Currently this analysis does not include the ARP packets (to be added).

### Frame 1: `trinload.py` scans network for SAM Coupés running TrinLoad

<pre>
<code>
# Start of <a href="https://en.wikipedia.org/wiki/Ethernet_frame#Structure">Layer 2 Ethernet Frame</a>
#   * Header:   14 octets
#   * Payload:  29 octets
#   * Padding:  17 octets
#   * Checksum:  4 octets
#   * Total:    64 octets

00-05: ff ff ff ff ff ff             Destination: <a href="https://en.wikipedia.org/wiki/Broadcast_address#Ethernet">broadcast</a> to all hosts on network
06-0b: xx xx xx xx xx xx             Source: Mac address of machine running `trinload.py` (self)
0c-0d: 08 00                         <a href="https://en.wikipedia.org/wiki/EtherType#Values">Ethertype</a> 0x0800 => IPv4

  # Start of <a href="https://en.wikipedia.org/wiki/Internet_Protocol_version_4#Packet_structure">IPv4 Packet</a>
  #   * Header:  20 octets
  #   * Payload:  9 octets
  #   * Total:   29 octets

  0e-0e: 45                          IP version: 4, Internet Header Length (IHL): 5 (32-bit words) (=> no IPv4 options specified)
  0f-0f: 00                          Differentiated Services Code Point (DSCP): 0b000000, Explicit Congestion Notification (ECN): 0b00
  10-11: 00 1d                       Total length of IPv4 packet: 0x001d (29 octets)
  12-13: xx xx                       Identification field (see <a href="https://www.rfc-editor.org/rfc/rfc6864">RFC 6864</a>)
  14-15: 00 00                       Flags: 0b000, Fragment Offset: 0b0000000000000
  16-16: 40                          Time to live: 64 seconds (but effectively, 64 hops)
  17-17: 11                          Protocol: UDP
  18-19: xx xx                       <a href="https://en.wikipedia.org/wiki/Internet_checksum#Computation">IPv4 Header checksum</a>
  1a-1d: xx xx xx xx                 IP address of self (machine running `trinload.py`)
  1e-21: ff ff ff ff                 IP address of destination (broadcast)

    # Start of <a href="https://en.wikipedia.org/wiki/User_Datagram_Protocol#UDP_datagram_structure">UDP Datagram</a>
    #   * Header:   8 octets
    #   * Payload:  1 octet
    #   * Total:    9 octets

    22-23: xx xx                     Source (UDP) Port (randomly assigned available port)
    24-25: ed b0                     Destination (UDP) Port 60848
    26-27: 00 09                     UDP Datagram Length: 9 (octets)
    28-29: xx xx                     UDP header checksum

      # Start of UDP Payload
      #   Payload:  1 octet
      #   Total:    1 octet

      2a-2a: 3f                      Payload (ASCII '?')

      # End of UDP Payload

    # End of UDP Datagram

  # End of IPv4 Packet

2b-3b: 00 00 00 00 00 00 00 00       Ethernet Frame Padding
       00 00 00 00 00 00 00 00
       00
3c-3f: xx xx xx xx                   <a href="https://en.wikipedia.org/wiki/Frame_check_sequence">Frame Check Sequence</a>

# End of Layer 2 Ethernet Frame
</code>
</pre>

### Frame 2: SAM running TrinLoad responds with `!`

<pre>
<code>
# Start of <a href="https://en.wikipedia.org/wiki/Ethernet_frame#Structure">Layer 2 Ethernet Frame</a>
#   * Header:   14 octets
#   * Payload:  29 octets
#   * Padding:  17 octets
#   * Checksum:  4 octets
#   * Total:    64 octets

00-05: xx xx xx xx xx xx             Destination: Mac address copied from Source field (06-0b) of frame 1
06-0b: xx xx xx xx xx xx             Source: Mac address of SAM running Trinload (self)
0c-0d: 08 00                         <a href="https://en.wikipedia.org/wiki/EtherType#Values">Ethertype</a> 0x0800 => IPv4

  # Start of <a href="https://en.wikipedia.org/wiki/Internet_Protocol_version_4#Packet_structure">IPv4 Packet</a>
  #   * Header:  20 octets
  #   * Payload:  9 octets
  #   * Total:   29 octets

  0e-0e: 45                          IP version: 4, Internet Header Length (IHL): 5 (32-bit words) (=> no IPv4 options specified)
  0f-0f: 00                          Differentiated Services Code Point (DSCP): 0b000000, Explicit Congestion Notification (ECN): 0b00
  10-11: 00 1d                       Total length of IPv4 packet: 0x001d (29 octets)
  12-13: xx xx                       Identification field (see <a href="https://www.rfc-editor.org/rfc/rfc6864">RFC 6864</a>)
  14-15: 00 00                       Flags: 0b000, Fragment Offset: 0b0000000000000
  16-16: 40                          Time to live: 64 seconds (but effectively, 64 hops)
  17-17: 11                          Protocol: UDP
  18-19: xx xx                       <a href="https://en.wikipedia.org/wiki/Internet_checksum#Computation">IPv4 Header checksum</a>
  1a-1d: xx xx xx xx                 IP address of SAM running Trinload (self)
  1e-21: xx xx xx xx                 IP address of machine running `trinload.py` (copied from 1a-1d of frame 1)

    # Start of <a href="https://en.wikipedia.org/wiki/User_Datagram_Protocol#UDP_datagram_structure">UDP Datagram</a>
    #   * Header:   8 octets
    #   * Payload:  1 octet
    #   * Total:    9 octets

    22-23: ed b0                     Source (UDP) Port 60848 (copied from 24-25 of frame 1)
    24-25: xx xx                     Destination (UDP) Port (copied from 22-23 of frame 1)
    26-27: 00 09                     UDP Datagram Length: 9 (octets)
    28-29: 00 00                     UDP (optional) header checksum (TrinLoad is allowed to not provide it)

      # Start of UDP Payload
      #   Payload:  1 octet
      #   Total:    1 octet

      2a-2a: 21                      Payload (ASCII '!')

      # End of UDP Payload

    # End of UDP Datagram

  # End of IPv4 Packet

2b-3b: 00 00 00 00 00 00 00 00       Ethernet Frame Padding
       00 00 00 00 00 00 00 00
       00
3c-3f: xx xx xx xx                   <a href="https://en.wikipedia.org/wiki/Frame_check_sequence">Frame Check Sequence</a>

# End of Layer 2 Ethernet Frame
</code>
</pre>

### Frame 3: `trinload.py` transfers data with `@`
<pre>
<code>

# Start of <a href="https://en.wikipedia.org/wiki/Ethernet_frame#Structure">Layer 2 Ethernet Frame</a>
#   * Header:   14 octets
#   * Payload:  48 octets
#   * Padding:   0 octets
#   * Checksum:  4 octets
#   * Total:    66 octets

00-05: xx xx xx xx xx xx             Destination: Mac address of SAM running Trinload
06-0b: xx xx xx xx xx xx             Source: Mac address of machin running `trinload.py` (self)
0c-0d: 08 00                         <a href="https://en.wikipedia.org/wiki/EtherType#Values">Ethertype</a> 0x0800 => IPv4

  # Start of <a href="https://en.wikipedia.org/wiki/Internet_Protocol_version_4#Packet_structure">IPv4 Packet</a>
  #   * Header:  20 octets
  #   * Payload: 28 octets
  #   * Total:   48 octets

  0e-0e: 45                          IP version: 4, Internet Header Length (IHL): 5 (32-bit words) (=> no IPv4 options specified)
  0f-0f: 00                          Differentiated Services Code Point (DSCP): 0b000000, Explicit Congestion Notification (ECN): 0b00
  10-11: 00 30                       Total length of IPv4 packet: 0x001d (48 octets)
  12-13: xx xx                       Identification field (see <a href="https://www.rfc-editor.org/rfc/rfc6864">RFC 6864</a>)
  14-15: 00 00                       Flags: 0b000, Fragment Offset: 0b0000000000000
  16-16: 40                          Time to live: 64 seconds (but effectively, 64 hops)
  17-17: 11                          Protocol: UDP
  18-19: xx xx                       <a href="https://en.wikipedia.org/wiki/Internet_checksum#Computation">IPv4 Header checksum</a>
  1a-1d: xx xx xx xx                 IP address of self (machine running `trinload.py`)
  1e-21: xx xx xx xx                 IP address of SAM running Trinload

    # Start of <a href="https://en.wikipedia.org/wiki/User_Datagram_Protocol#UDP_datagram_structure">UDP Datagram</a>
    #   * Header:   8 octets
    #   * Payload: 20 octets
    #   * Total:   28 octets

    22-23: xx xx                     Source (UDP) Port
    24-25: ed b0                     Destination (UDP) Port 60848
    26-27: 00 1c                     UDP Datagram Length: 28 (octets)
    28-29: xx xx                     UDP header checksum

      # Start of UDP Payload
      #   Payload:  20 octets
      #   Total:    20 octets

      2a-2a: 40                      Payload (ASCII '@')
      2b-2b: 01                      SAM Page number
      2c-2d: 00 00                   Offset, little endian

      # Executable code

      2e-30: 01 32 00                ld bc, 50
      31-32: 3e 07                   ld a, 7
      33-34: d3 fe                   L1: out (254), a
      35-35: 41                      ld b,c
      36-36: 76                      L2: halt
      37-38: 10 fd                   djnz L2
      39-39: 3d                      dec a
      3a-3c: f2 05 80                jp p,L1
      3d-3d: c9                      ret

      # End of UDP Payload

    # End of UDP Datagram

  # End of IPv4 Packet

3e-41: xx xx xx xx                   <a href="https://en.wikipedia.org/wiki/Frame_check_sequence">Frame Check Sequence</a>

# End of Layer 2 Ethernet Frame
</code>
</pre>

### Frame 4: SAM acknowledges successful receipt of block with `@`
<pre>
<code>

# Start of <a href="https://en.wikipedia.org/wiki/Ethernet_frame#Structure">Layer 2 Ethernet Frame</a>
#   * Header:   14 octets
#   * Payload:  32 octets
#   * Padding:  14 octets
#   * Checksum:  4 octets
#   * Total:    64 octets

00-05: xx xx xx xx xx xx             Destination: Mac address copied from Source field (06-0b) of frame 1
06-0b: xx xx xx xx xx xx             Source: Mac address of SAM running Trinload (self)
0c-0d: 08 00                         <a href="https://en.wikipedia.org/wiki/EtherType#Values">Ethertype</a> 0x0800 => IPv4

  # Start of <a href="https://en.wikipedia.org/wiki/Internet_Protocol_version_4#Packet_structure">IPv4 Packet</a>
  #   * Header:  20 octets
  #   * Payload: 12 octets
  #   * Total:   32 octets

  0e-0e: 45                          IP version: 4, Internet Header Length (IHL): 5 (32-bit words) (=> no IPv4 options specified)
  0f-0f: 00                          Differentiated Services Code Point (DSCP): 0b000000, Explicit Congestion Notification (ECN): 0b00
  10-11: 00 20                       Total length of IPv4 packet: 0x001d (32 octets)
  12-13: xx xx                       Identification field (see <a href="https://www.rfc-editor.org/rfc/rfc6864">RFC 6864</a>)
  14-15: 00 00                       Flags: 0b000, Fragment Offset: 0b0000000000000
  16-16: 40                          Time to live: 64 seconds (but effectively, 64 hops)
  17-17: 11                          Protocol: UDP
  18-19: xx xx                       <a href="https://en.wikipedia.org/wiki/Internet_checksum#Computation">IPv4 Header checksum</a>
  1a-1d: xx xx xx xx                 IP address of SAM running Trinload (self)
  1e-21: xx xx xx xx                 IP address of machine running `trinload.py` (copied from 1a-1d of frame 1)

    # Start of <a href="https://en.wikipedia.org/wiki/User_Datagram_Protocol#UDP_datagram_structure">UDP Datagram</a>
    #   * Header:   8 octets
    #   * Payload:  4 octet
    #   * Total:   12 octets

    22-23: ed b0                     Source (UDP) Port 60848 (copied from 24-25 of frame 1)
    24-25: xx xx                     Destination (UDP) Port (copied from 22-23 of frame 1)
    26-27: 00 0c                     UDP Datagram Length: 12 (octets)
    28-29: 00 00                     UDP (optional) header checksum (TrinLoad is allowed to not provide it)

      # Start of UDP Payload
      #   Payload:  4 octets
      #   Total:    4 octets

      2a-2a: 40                      Payload (ASCII '@')
      2b-2b: 01                      SAM Page number
      2c-2d: 00 00                   Offset, little endian

      # End of UDP Payload

    # End of UDP Datagram

  # End of IPv4 Packet

2e-3b: 00 00 00 00 00 00 00 00       Ethernet Frame Padding
       00 00 00 00 00 00
3c-3f: xx xx xx xx                   <a href="https://en.wikipedia.org/wiki/Frame_check_sequence">Frame Check Sequence</a>

# End of Layer 2 Ethernet Frame
</code>
</pre>

### Frame 5: `trinload.py` triggers remote execution of code
<pre>
<code>

# Start of <a href="https://en.wikipedia.org/wiki/Ethernet_frame#Structure">Layer 2 Ethernet Frame</a>
#   * Header:   14 octets
#   * Payload:  32 octets
#   * Padding:  14 octets
#   * Checksum:  4 octets
#   * Total:    64 octets

00-05: xx xx xx xx xx xx             Destination: Mac address of SAM running Trinload
06-0b: xx xx xx xx xx xx             Source: Mac address of machin running `trinload.py` (self)
0c-0d: 08 00                         <a href="https://en.wikipedia.org/wiki/EtherType#Values">Ethertype</a> 0x0800 => IPv4

  # Start of <a href="https://en.wikipedia.org/wiki/Internet_Protocol_version_4#Packet_structure">IPv4 Packet</a>
  #   * Header:  20 octets
  #   * Payload: 12 octets
  #   * Total:   32 octets

  0e-0e: 45                          IP version: 4, Internet Header Length (IHL): 5 (32-bit words) (=> no IPv4 options specified)
  0f-0f: 00                          Differentiated Services Code Point (DSCP): 0b000000, Explicit Congestion Notification (ECN): 0b00
  10-11: 00 20                       Total length of IPv4 packet: 0x001d (32 octets)
  12-13: xx xx                       Identification field (see <a href="https://www.rfc-editor.org/rfc/rfc6864">RFC 6864</a>)
  14-15: 00 00                       Flags: 0b000, Fragment Offset: 0b0000000000000
  16-16: 40                          Time to live: 64 seconds (but effectively, 64 hops)
  17-17: 11                          Protocol: UDP
  18-19: xx xx                       <a href="https://en.wikipedia.org/wiki/Internet_checksum#Computation">IPv4 Header checksum</a>
  1a-1d: xx xx xx xx                 IP address of self (machine running `trinload.py`)
  1e-21: xx xx xx xx                 IP address of SAM running Trinload

    # Start of <a href="https://en.wikipedia.org/wiki/User_Datagram_Protocol#UDP_datagram_structure">UDP Datagram</a>
    #   * Header:   8 octets
    #   * Payload:  4 octets
    #   * Total:   12 octets

    22-23: xx xx                     Source (UDP) Port
    24-25: ed b0                     Destination (UDP) Port 60848
    26-27: 00 0c                     UDP Datagram Length: 12 (octets)
    28-29: xx xx                     UDP header checksum

      # Start of UDP Payload
      #   Payload:   4 octets
      #   Total:     4 octets

      2a-2a: 58                      Payload (ASCII 'X')
      2b-2b: 01                      SAM HMPR page number
      2c-2d: 00 80                   Execution Address, little endian (32768)

      # End of UDP Payload

    # End of UDP Datagram

  # End of IPv4 Packet

2e-3b: 00 00 00 00 00 00 00 00       Ethernet Frame Padding
       00 00 00 00 00 00
3c-3f: xx xx xx xx                   <a href="https://en.wikipedia.org/wiki/Frame_check_sequence">Frame Check Sequence</a>

# End of Layer 2 Ethernet Frame
</code>
</pre>

### Frame 6: SAM acknowledges receipt of remote execution request
<pre>
<code>

# Start of <a href="https://en.wikipedia.org/wiki/Ethernet_frame#Structure">Layer 2 Ethernet Frame</a>
#   * Header:   14 octets
#   * Payload:  32 octets
#   * Padding:  14 octets
#   * Checksum:  4 octets
#   * Total:    64 octets

00-05: xx xx xx xx xx xx             Destination: Mac address copied from Source field (06-0b) of frame 1
06-0b: xx xx xx xx xx xx             Source: Mac address of SAM running Trinload (self)
0c-0d: 08 00                         <a href="https://en.wikipedia.org/wiki/EtherType#Values">Ethertype</a> 0x0800 => IPv4

  # Start of <a href="https://en.wikipedia.org/wiki/Internet_Protocol_version_4#Packet_structure">IPv4 Packet</a>
  #   * Header:  20 octets
  #   * Payload: 12 octets
  #   * Total:   32 octets

  0e-0e: 45                          IP version: 4, Internet Header Length (IHL): 5 (32-bit words) (=> no IPv4 options specified)
  0f-0f: 00                          Differentiated Services Code Point (DSCP): 0b000000, Explicit Congestion Notification (ECN): 0b00
  10-11: 00 20                       Total length of IPv4 packet: 0x001d (32 octets)
  12-13: xx xx                       Identification field (see <a href="https://www.rfc-editor.org/rfc/rfc6864">RFC 6864</a>)
  14-15: 00 00                       Flags: 0b000, Fragment Offset: 0b0000000000000
  16-16: 40                          Time to live: 64 seconds (but effectively, 64 hops)
  17-17: 11                          Protocol: UDP
  18-19: xx xx                       <a href="https://en.wikipedia.org/wiki/Internet_checksum#Computation">IPv4 Header checksum</a>
  1a-1d: xx xx xx xx                 IP address of SAM running Trinload (self)
  1e-21: xx xx xx xx                 IP address of machine running `trinload.py` (copied from 1a-1d of frame 1)

    # Start of <a href="https://en.wikipedia.org/wiki/User_Datagram_Protocol#UDP_datagram_structure">UDP Datagram</a>
    #   * Header:   8 octets
    #   * Payload:  4 octet
    #   * Total:   12 octets

    22-23: ed b0                     Source (UDP) Port 60848 (copied from 24-25 of frame 1)
    24-25: xx xx                     Destination (UDP) Port (copied from 22-23 of frame 1)
    26-27: 00 0c                     UDP Datagram Length: 12 (octets)
    28-29: 00 00                     UDP (optional) header checksum (TrinLoad is allowed to not provide it)

      # Start of UDP Payload
      #   Payload:  4 octets
      #   Total:    4 octets

      2a-2a: 58                      Payload (ASCII 'X')
      2b-2b: 01                      SAM HMPR page number
      2c-2d: 00 80                   Execution Address, little endian (32768)

      # End of UDP Payload

    # End of UDP Datagram

  # End of IPv4 Packet

2e-3b: 00 00 00 00 00 00 00 00       Ethernet Frame Padding
       00 00 00 00 00 00
3c-3f: xx xx xx xx                   <a href="https://en.wikipedia.org/wiki/Frame_check_sequence">Frame Check Sequence</a>

# End of Layer 2 Ethernet Frame
</code>
</pre>
