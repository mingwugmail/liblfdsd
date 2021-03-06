#!/usr/bin/env dub
/+ dub.sdl:
name "app"
dependency "elembuf" version="~>1.2.2"
dflags "-release" "-m64" "-boundscheck=off" "-O" platform="dmd"
dflags "-O4" "--release" "--boundscheck=off" platform="ldc2"
+/

// dmd.exe  -release -m64 -boundscheck=off -O  buffer.d
// ldc2 -O4 --release --boundscheck=off buffer.d

import std.stdio;
import std.datetime.stopwatch;
import core.atomic;
import core.thread, std.concurrency;

import elembuf;

const n=1_000_000_000; //;_000
enum amount = n;


void main() //line 22
{
    auto buffer = tbuffer(size_t[].init);

	size_t srci = 0; // Source index
	size_t consi = 0; // Consumer index

    size_t sum = 0; 

    size_t delegate(size_t[]) src = (size_t[] x) // Tell background thread about source
    {
		const needToFill = amount - srci;

		if( x.length >= needToFill ) // Final fill!
		{
			foreach(i;0..needToFill){
				x[i] = srci;
				srci++;
			}
			return needToFill;
		}
		else // Long way to go still...
		{
			foreach(ref i;x){
				i = srci;
				srci++;
			}
			return x.length;
		}

    }; 

	buffer ~= src;

	// START!
	StopWatch sw;
   	sw.start();  

	while(consi < amount)
	{
		buffer ~= buffer.source;

		foreach(elem; buffer)
			sum += elem;

		consi += buffer.length;

		buffer = buffer[$..$];
	}

	sw.stop();
   	writeln("finished receiving");
   	writefln("received %d messages in %d msec sum=%d speed=%d msg/msec", n, sw.peek().total!("msecs"), sum, n/sw.peek().total!("msecs"));

	buffer.deinit;

}
