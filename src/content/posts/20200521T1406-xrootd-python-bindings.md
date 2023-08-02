---
title: XRootD python bindings from source
date: 2020-05-21T14:06:00+02:00
---
When xrootd has been already installed on cluster, but you need xrootd-python bindings in your virtualenv, it might be
complicated to use system version (if it is present :) ).

In the later versions of xrootd `XRD_LIBDIR` and `XRD_INCDIR` env vars [were introduced](https://github.com/xrootd/xrootd/tree/master/bindings/python):

> If you have xrootd installed and the installation still fails, do XRD_LIBDIR=XYZ; XRD_INCDIR=ZYX; pip install xrootd where XYZ and ZYX are the paths to the XRootD library and include directories on your system.

## Trials and errors:

* `XRD_LIBDIR=/usr/lib XRD_INCDIR=/usr/include/xrootd pip install xrootd==4.11.3` failed for me with error:

```bash
    creating /usr/local/lib64/python3.6
    error: could not create '/usr/local/lib64/python3.6': Permission denied
    Traceback (most recent call last):
      File "<string>", line 1, in <module>
      File "/tmp/pip-install-zt8tt21q/xrootd/setup.py", line 137, in <module>
        'bdist_wheel': CustomWheelGen
      File "/path/to/virtualenv/lib64/python3.6/site-packages/setuptools/__init__.py", line 129, in setup
        return distutils.core.setup(**attrs)
      File "/usr/lib64/python3.6/distutils/core.py", line 148, in setup
        dist.run_commands()
      File "/usr/lib64/python3.6/distutils/dist.py", line 955, in run_commands
        self.run_command(cmd)
      File "/usr/lib64/python3.6/distutils/dist.py", line 974, in run_command
        cmd_obj.run()
      File "/tmp/pip-install-zt8tt21q/xrootd/setup.py", line 97, in run
        raise Exception( 'Install step failed!' )
    Exception: Install step failed!
```

* When installing from source `XRD_LIBDIR=/usr/lib XRD_INCDIR=/usr/include/xrootd pip install .` from `xrootd/bindings/python/build`:

```bash
In file included from /afs/cern.ch/user/a/ananiev/src/xrootd/bindings/python/src/PyXRootDCopyProcess.cc:26:0:
    /path/to/xrootd/bindings/python/src/PyXRootDCopyProcess.hh:30:37: fatal error: XrdCl/XrdClCopyProcess.hh: No such file or directory
     #include "XrdCl/XrdClCopyProcess.hh"
                                         ^
    compilation terminated.
    error: command '/usr/bin/cc' failed with exit status 1
```

It is possible that I didn't understand correctly how to use these env vars. After all I came up with another solution.

## Solution:

```bash
git clone https://github.com/xrootd/xrootd.git
cd xrootd
git checkout stabe-4.1.x  # or whatever version you have installed
cd bindings/python
mkdir build
cd build
cmake ..
```

A new file `setup.py` has been generated. It lacks paths to lib and include dirs of already installed xrootd. Find
these lines, and update `include_dirs` and `library_dirs` to contain paths to xrootd.

```python
ext_modules      = [
   Extension(
       'pyxrootd.client',
       sources   = sources,
       depends   = depends,
       libraries = ['XrdCl', 'XrdUtils', 'dl'],
       extra_compile_args = ['-g'],
       include_dirs = [xrdsrcincdir, xrdbinincdir, "/usr/include/xrootd"],
       library_dirs = [xrdlibdir, xrdcllibdir, "/usr/lib"]
       )
   ]
```

Now `pip install .` should work.
