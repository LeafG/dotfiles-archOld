#!/bin/sh

ind=$(xkblayout-state print %s)

if [ "$ind" == "il" ]; then
	echo -n "HE"
else
	echo -n "$ind"
fi

#if ($ind==il) then 
#    echo -n "HE"
#else
#    echo -n "US"
#fi

#echo -n $ind

