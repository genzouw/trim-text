# trim-text

[![Docker Pulls](https://img.shields.io/docker/pulls/genzouw/trim-text.svg?style=for-the-badge)](https://hub.docker.com/r/genzouw/trim-text/)
[![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/genzouw/trim-text.svg?style=for-the-badge)](https://hub.docker.com/r/genzouw/trim-text/)

[![dockeri.co](https://dockeri.co/image/genzouw/trim-text)](https://hub.docker.com/r/genzouw/trim-text)

## Description

This Docker image is intended to provide a UI that integrates command line text cut operations.

## Demo

```bash
# Create sample file.
$ cat >sample.txt <<EOF
1****
*2***
**3**
***4*
****5
EOF

# Remove one line from top, bottom, left and right
$ cat sample.txt | docker run -i genzouw/trim-text -t1 -b1 -l1 -r1
2**
*3*
**4

# Same as previous example
$ docker run -i genzouw/trim-text -t1 -b1 -l1 -r1 < sample.txt
2**
*3*
**4
```

It is convenient to set the following aliases.

```bash
$ echo "alias tt='docker run -i genzouw/trim-text'" >> ~/.bashrc

$ alias tt='docker run -i genzouw/trim-text'
```

## Requirements

* [Docker](https://www.docker.com)

## Installation

No installation is required.

## Usage

You have the following options:

* `-t` : Number of characters to trim from **top**
* `-b` : Number of characters to trim from **bottom**
* `-l` : Number of characters to trim from **left**
* `-r` : Number of characters to trim from **right**

## Relase Note

|date      |version|note          |
|---       |---    |---           |
|2019-10-08|1.0.0    |first release.|


## License

This software is released under the MIT License, see LICENSE.


## Author Information

[genzouw](https://genzouw.com)

* Twitter   : @genzouw ( https://twitter.com/genzouw )
* Facebook  : genzouw ( https://www.facebook.com/genzouw )
* LinkedIn  : genzouw ( https://www.linkedin.com/in/genzouw/ )
* Gmail     : genzouw@gmail.com
