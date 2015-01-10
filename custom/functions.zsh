function finderpath() {
    echo $(/usr/bin/osascript << EOF
    tell application "Finder"
        if current view of window 1 is in {list view, flow view} and selection is not {} then
            set i to item 1 of (get selection)
            if class of i is folder then
                set p to i
            else
                set p to container of i
            end if
        else
            set p to folder of window 1
        end if
        return POSIX path of (p as alias)
    end tell
    EOF)
}

function cdf() {
    cd "$(finderpath)"
}

urlencode() {
    setopt localoptions extendedglob
    input=( ${(s::)*} )
    print ${(j::)input/(#b)([^A-Za-z0-9_.\!~*\'\(\)-])/%${(l:2::0:)$(([##16]#match))}}
}

function dash() {
    search_string=$(urlencode $*)
    open dash://$search_string
}
