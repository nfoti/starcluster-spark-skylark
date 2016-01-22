
import os
import sys
import glob
import subprocess
import shutil


def run_command(cmd, ignore_failure=False, failure_callback=None,
                get_output=False):
    kwargs = {}
    if get_output:
        kwargs.update(dict(stdout=subprocess.PIPE, stderr=subprocess.PIPE))
    p = subprocess.Popen(cmd, shell=True, **kwargs)
    output = []
    if get_output:
        line = None
        while line != '':
            line = p.stdout.readline()
            if line != '':
                output.append(line)
                print line,
        for line in p.stderr.readlines():
            if line != '':
                output.append(line)
                print line,
    retval = p.wait()
    if retval != 0:
        errmsg = "command '%s' failed with status %d" % (cmd, retval)
        if failure_callback:
            ignore_failure = failure_callback(retval)
        if not ignore_failure:
            raise Exception(errmsg)
        else:
            sys.stderr.write(errmsg + '\n')
    if get_output:
        return retval, ''.join(output)
    return retval

if __name__ == "__main__":

    run_command('rm -rf /run/resolvconf')
    run_command('rm -f /etc/mtab')

    # Clean up everything in /root so that we can bake the AMI without any info
    run_command('rm -rf /root/*')
    # Note, we keep .ssh around so that we can use `ebsimage` or `s3image` to
    # create the image. Those functions remove that before they create the
    # snapshot.
    exclude = ['/root/.bashrc', '/root/.profile', '/root/.bash_aliases',
                '/root/.ssh']
    for dot in glob.glob("/root/*"):
        if dot not in exclude:
            run_command('rm -rf %s' % dot)
    for dot in glob.glob("/root/.*"):
        if dot not in exclude:
            run_command('rm -rf %s' % dot)

    for path in glob.glob('/usr/local/src/*'):
        if os.path.isdir(path):
            shutil.rmtree(path)
    run_command('rm -f /var/cache/apt/archives/*.deb')
    run_command('rm -f /var/cache/apt/archives/partial/*')
    for f in glob.glob('/etc/profile.d'):
        if 'byobu' in f:
            run_command('rm -f %s' % f)
    if os.path.islink('/sbin/initctl') and os.path.isfile('/sbin/initctl.bak'):
        run_command('mv -f /sbin/initctl.bak /sbin/initctl')
