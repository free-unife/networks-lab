# networks-lab
LaTeX and source code files related to "Laboratorio di reti" course in UNIFE 
(University of Ferrara), year 2014-2015.

## Status of art
All the material in this repository is "as-is", i.e: it has not yet been 
reprocessed to be clear and usable. Since there are quite a lot of files, and 
the fact that this is a repository with the least priority among all, the 
processing may take a long time.

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

