# networks-lab
LaTeX and source code files related to "Laboratorio di reti" course in UNIFE 
(University of Ferrara), year 2014-2015.

## Status of art
All the material in this repository is "as-is", i.e: it has not yet been 
reprocessed to be clear and usable. Since there are quite a lot of files, and 
the fact that this is a repository with the least priority among all, the 
processing may take a long time.

## Wiki contributions
The following is a list of Arch Linux wiki pages contributed because of this 
course:
- [Dovecot](https://wiki.archlinux.org/index.php?title=Dovecot&diff=prev&oldid=370632)
- [Amavis](https://wiki.archlinux.org/index.php?title=Amavis&diff=prev&oldid=370822)
- [Amavis](https://wiki.archlinux.org/index.php?title=Amavis&diff=prev&oldid=370850)
- [Amavis](https://wiki.archlinux.org/index.php?title=Amavis&diff=prev&oldid=370909)
- [Amavis](https://wiki.archlinux.org/index.php?title=Amavis&diff=prev&oldid=371074)
- [PostFix Howto With SASL](https://wiki.archlinux.org/index.php?title=PostFix_Howto_With_SASL&diff=prev&oldid=371426)
- [PostFix Howto With SASL](https://wiki.archlinux.org/index.php?title=PostFix_Howto_With_SASL&diff=prev&oldid=371433)
- [PostFix Howto With SASL](https://wiki.archlinux.org/index.php?title=PostFix_Howto_With_SASL&diff=prev&oldid=371435)
- [PostFix Howto With SASL](https://wiki.archlinux.org/index.php?title=PostFix_Howto_With_SASL&diff=prev&oldid=371769)
- [Amavis](https://wiki.archlinux.org/index.php?title=Amavis&diff=prev&oldid=371770)
- [PostFix](https://wiki.archlinux.org/index.php?title=Postfix&diff=prev&oldid=371771)

## How to compile and compress the resulting pdf file:
```
$ pdflatex file.tex
$ gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressedFile.pdf file.pdf

```

# License
Source code and documentation sometimes overlap and for this reason they are 
both released under the::

![https://www.gnu.org/graphics/gplv3-127x51.png](https://www.gnu.org/graphics/gplv3-127x51.png)


Copyright (C) 2016 frnmst (Franco Masotti) <franco.masotti@live.com>
<franco.masotti@student.unife.it>, dannylessio (Danny Lessio)

networks-lab is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

