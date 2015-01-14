#!/usr/bin/python

import sys
import whdcli
import logging
import subprocess

LOG_FILENAME = '/var/log/check_csr.out'

logging.basicConfig(filename=LOG_FILENAME, level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info('Start script')

logger.debug("Number of arguments: %s ",len(sys.argv))
logger.info("Hostname: %s ", sys.argv[1])

if sys.argv[1] is "puppet":
	logger.info("It's the puppetmaster, of course we approve it.")
	sys.exit(0)

certreq = sys.stdin.read()
logger.debug("CSR: %s", certreq)

cmd = ['/usr/bin/openssl', 'req', '-noout', '-text']
proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
(output, err) = proc.communicate(certreq)

logger.debug("CSR output: %s", output)
logger.debug("CSR error: %s", err)

lineList = output.splitlines()

strippedLineList = [line.lstrip() for line in lineList]
strippedLineList2 = [line.rstrip() for line in strippedLineList]

logger.debug("Stripped list: %s", strippedLineList2)

trusted_attribute1 = strippedLineList2.index("1.3.6.1.4.1.34380.1.2.1.1:")

logger.debug("trusted_attribute1 index: %s", trusted_attribute1)

serial_number = strippedLineList2[trusted_attribute1+1]

logger.info("Serial number: %s", serial_number)   

# Now we get actual work done
whd_prefs = whdcli.WHDPrefs("/home/whdcli/com.github.nmcspadden.whd-cli.plist")
w = whdcli.WHD(whd_prefs, None, None, False)
if not w.getAssetBySerial(serial_number):
        logger.info("Serial number not found in inventory.")
        sys.exit(1)

logger.info("Found serial number in inventory. Approving.")
sys.exit(0)
