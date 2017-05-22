#!/usr/bin/env python
from __future__ import print_function
import subprocess
import sys
import unittest
import xmlrunner
import os
import io
import shutil
import copy

WORKSPACE = os.path.abspath(os.getenv('WORKSPACE', '/tmp'))
FIXTURES = os.path.join(os.getcwd(), "tests/fixtures")
FAKE_CMD_LIST = os.path.join(WORKSPACE, "cmd_list")
FAKE_BIN = os.path.join(WORKSPACE, "bin")
FAKE_PATH = "%s:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin" % FAKE_BIN


def executeAndReturnOutput(command):
    p = subprocess.Popen(command, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    stdoutdata, stderrdata = p.communicate()
    #print(stdoutdata, file=sys.stdout)
    print(stderrdata, file=sys.stderr)
    return p.returncode, stdoutdata, stderrdata


def create_prog(filename, command):
    """Create test program.

    :param unicode filename: destination filename
    :param unicode command: command to write to test program
    """
    with io.open(filename, 'w', encoding='utf-8') as fp:
        fp.write(u"#!/bin/bash\n%s\n" % (command, ))
        os.fchmod(fp.fileno(), 0o755)


def setnode(active=True):
    if active:
        mode = 'true'
    else:
        mode = 'false'
    create_prog(os.path.join(FAKE_BIN, 'ngcp-check_active'), mode)

command = [
    "env",
    "PATH=%s" % FAKE_PATH,
    "./scripts/ngcp-dlgcnt-check", "-r"]

FAKE_DLG_CLEAN = """
if [ $1 = -c ] ; then
    echo 4
    exit 0
fi
if [ $1 = -C ] ; then
    echo localhost
    exit 0
fi
echo "ngcp-dlgcnt-clean $*">> %s""" % FAKE_CMD_LIST

FAKE_REDIS_HELPER = """
if [ $1 != -h ] && [ $2 != localhost ] ; then
    echo $0 $* >&2
    exit 1
fi
if [ $3 != -n ] && [ $4 != 4 ] ; then
    echo $0 $* >&2
    exit 1
fi"""


class TestDlgCnt(unittest.TestCase):

    def checkNotCmd(self):
        self.assertFalse(os.path.exists(FAKE_CMD_LIST),
                         "%s found" % FAKE_CMD_LIST)

    def checkCmd(self, f, f2):
        self.assertTrue(os.path.exists(f), "%s not found" % f)
        self.assertTrue(os.path.exists(f2), "%s not found" % f2)
        res = executeAndReturnOutput(
            ['diff', '-uNb', f, f2])
        self.assertEqual(res[0], 0, res[1])

    def setUp(self):
        self.command = copy.deepcopy(command)
        if not os.path.exists(FAKE_BIN):
            os.makedirs(FAKE_BIN)
        setnode(True)
        create_prog(os.path.join(FAKE_BIN, 'ngcp-dlgcnt-clean'),
                    FAKE_DLG_CLEAN)
        create_prog(os.path.join(FAKE_BIN, 'ngcp-dlglist-clean'),
                    'echo "ngcp-dlglist-clean $*">> %s' % FAKE_CMD_LIST)

    def tearDown(self):
        shutil.rmtree(WORKSPACE)

    def test_wrong_option(self):
        self.command = ["./scripts/ngcp-dlgcnt-check", "-k"]
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 1, res[2])
        self.assertRegexpMatches(res[2], 'illegal option')
        self.checkNotCmd()

    def test_help(self):
        self.command = ["./scripts/ngcp-dlgcnt-check", "-h"]
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[2])
        self.assertRegexpMatches(res[1], '\toptions\n')
        self.checkNotCmd()

    def test_inactive(self):
        setnode(False)
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 3, res[1])
        self.checkNotCmd()

    def test_noredisconf(self):
        create_prog(os.path.join(FAKE_BIN, 'ngcp-dlgcnt-clean'),
                    'echo "error" >&2; false')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-sercmd'),
                    "true")
        create_prog(os.path.join(FAKE_BIN, 'ngcp-redis-helper'),
                    "%s; true" % FAKE_REDIS_HELPER)
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[1])
        self.checkNotCmd()

    def test_redisconf(self):
        create_prog(os.path.join(FAKE_BIN, 'ngcp-sercmd'),
                    "true")
        create_prog(os.path.join(FAKE_BIN, 'ngcp-redis-helper'),
                    "%s; true" % FAKE_REDIS_HELPER)
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[1])
        self.checkNotCmd()

    def test_empty(self):
        create_prog(os.path.join(FAKE_BIN, 'ngcp-sercmd'),
                    "true")
        create_prog(os.path.join(FAKE_BIN, 'ngcp-redis-helper'),
                    "true")
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[1])
        self.checkNotCmd()

    def test_empty_line(self):
        create_prog(os.path.join(FAKE_BIN, 'ngcp-sercmd'),
                    "echo")
        create_prog(os.path.join(FAKE_BIN, 'ngcp-redis-helper'),
                    "echo")
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[1])
        self.checkNotCmd()

    def test_okredis(self):
        FAKE_DLG = os.path.join(FIXTURES, 'okredis.dlg')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-sercmd'),
                    "cat %s" % (FAKE_DLG))
        FAKE_REDIS = os.path.join(FIXTURES, 'okredis.redis')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-redis-helper'),
                    "cat %s" % (FAKE_REDIS))
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[2])
        self.checkNotCmd()

    def test_koredis(self):
        FAKE_DLG = os.path.join(FIXTURES, 'koredis.dlg')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-sercmd'),
                    "cat %s" % (FAKE_DLG))
        FAKE_REDIS = os.path.join(FIXTURES, 'koredis.redis')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-redis-helper'),
                    "cat %s" % (FAKE_REDIS))
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[2])
        self.checkCmd(os.path.join(FIXTURES, 'koredis.cmd'),
                      FAKE_CMD_LIST)

    def test_kodlgclean(self):
        FAKE_DLG = os.path.join(FIXTURES, 'koredis.dlg')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-sercmd'),
                    "cat %s" % (FAKE_DLG))
        FAKE_REDIS = os.path.join(FIXTURES, 'koredis.redis')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-redis-helper'),
                    "cat %s" % (FAKE_REDIS))
        create_prog(os.path.join(FAKE_BIN, 'ngcp-dlgcnt-clean'),
                    '%s; false' % FAKE_DLG_CLEAN)
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[2])
        self.checkCmd(os.path.join(FIXTURES, 'koredis.cmd'),
                      FAKE_CMD_LIST)

    def test_kolistclean(self):
        FAKE_DLG = os.path.join(FIXTURES, 'koredis.dlg')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-sercmd'),
                    "cat %s" % (FAKE_DLG))
        FAKE_REDIS = os.path.join(FIXTURES, 'koredis.redis')
        create_prog(os.path.join(FAKE_BIN, 'ngcp-redis-helper'),
                    "cat %s" % (FAKE_REDIS))
        create_prog(os.path.join(FAKE_BIN, 'ngcp-dlglist-clean'),
                    'echo "ngcp-dlglist-clean $*">> %s; false' % FAKE_CMD_LIST)
        res = executeAndReturnOutput(self.command)
        self.assertEqual(res[0], 0, res[2])
        self.checkCmd(os.path.join(FIXTURES, 'koredis.cmd'),
                      FAKE_CMD_LIST)

if __name__ == '__main__':
    unittest.main(
        testRunner=xmlrunner.XMLTestRunner(output=sys.stdout),
        # these make sure that some options that are not applicable
        # remain hidden from the help menu.
        failfast=False, buffer=False, catchbreak=False)