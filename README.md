<div align="center">

# wallpaper_reddit

<img src="https://user-images.githubusercontent.com/8348199/88131440-92576c00-cc0f-11ea-8d75-814c93c8e950.png" height="250px" width="250px">

A new wallpaper every day

![Version](https://img.shields.io/github/v/release/ahauser31/wallpaper_reddit?sort=semver)  [![Codacy Badge](https://app.codacy.com/project/badge/Grade/156864fc024443beb9e06e173b872365)](https://www.codacy.com/manual/ahauser31/wallpaper_reddit?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ahauser31/wallpaper_reddit&amp;utm_campaign=Badge_Grade)  ![platform](https://img.shields.io/badge/platform-Linux%7CmacOS%7CWindows-informational)  ![license](https://img.shields.io/github/license/ahauser31/wallpaper_reddit)

## Shell script to download wallpapers from picture subreddits

</div>

## Dependencies

The script mostly uses small terminal applications; however, some / all of the below may not be available on your system and need to be installed separately:

*   To process JSON: [jq](https://stedolan.github.io/jq/)
*   To download files: [curl](https://curl.haxx.se/)
*   To determine image dimensions: [identify (part of ImageMagick)](https://imagemagick.org/)

## Usage

Running just the script without any parameters just downloads a new wallpaper from the `wallpaper` subreddit to the your `$HOME/pictures/wallpapers/reddit` folder (folder gets created if it does not exist) and prints the file name:

```bash
-> ./wallpaper_reddit.sh
/Users/sample/Pictures/wallpapers/reddit/mxg1mwlu84c51.jpg
```

Images are considered suitable by default if they have a size of at least `1920x1080` and an aspect ration between `3/4` to `21/9`.  

A new image is only downloaded if the date changed from the time of the previous download, otherwise the script
just returns the old filename. This is accomplished by saving the most recently downloaded filename and the date of download in the file `$HOME/pictures/wallpapers/reddit/wallpaper.txt`.  

If a suitable image was found but it already exists in the `$HOME/pictures/wallpapers/reddit` folder, it is skipped and the next suitable image is downloaded instead.

## Options

Most of the defaults can be overriden using command line parameters:

| Parameter        | Description                                                             |
| ---------------- | ----------------------------------------------------------------------- |
| -h               | show usage info                                                         |
| -f               | force download of new image, even if there was already a download today |
| -n               | do not shuffle downloaded list of wallpaper candidates                  |
| -v               | verbose - print additional information to the terminal                  |
| -p \<path\>      | path to save downloaded images and history file to                      |
| -s \<sort\>      | reddit sort order (hot, top, new)                                       |
| -r \<subreddit\> | name of subreddit to download from (e.g. wallpaper)                     |
| -m \<maxlinks\>  | number of links to get from reddit                                      |
| -w \<minwidth\>  | minimum width of suitable images                                        |
| -e \<minheight\> | minimum height of suitable image                                        |
| -i \<minratio\>  | minimum image ratio of suitable images (e.g. 3/4)                       |
| -a \<maxratio\>  | maximum image ratio of suitable images (e.g. 21/9)                      |

If the wallpaper is intended to be used on a screen in portrait orientation, the ratios should be flipped to get images that are higher than they are wide.  

The number of links to download has an influence on runtime, but if a too low number is chosen, a suitable image that has not been downloaded before may not be found.

## Configuration

The script does not use configuration files at this time; to permanently change the defaults, please just edit the first section of the script itself. The section is heavily commented to facility this.

## Ideas / Suggestions / Issues

Please create a github issue if you have any ideas or suggestions for improvment or if you encounter a bug.
Currently, the script does only do limited error checking; this works for me but may be added in the future.

## Credit

This script was inspired by a Python tool & blog post by [Chris Titus Tech](https://christitus.com/change-wallpaper/), which itself is based on <https://github.com/markubiak/wallpaper-reddit>.  
Both these versions work fine and you should check them out. I just prefer to have a tool like this in a shell script as opposed to using Python for this (perhaps inspired by [Luke Smith](https://lukesmith.xyz/)).
