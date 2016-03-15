#!/usr/bin/env python
# coding=utf-8
import sys,os,platform
import ConfigParser
import syslog
from shutil import copy2
from filecmp import cmp
from zabbix_api import ZabbixAPI
## Configuration parameters
syslog.openlog(__file__)
config=ConfigParser.RawConfigParser()
config.read('/etc/deploy_scripts/create_linux_users.ini')
# credentails from itlogic base | настройки подключения к БД ITLogic
itldb_host=config.get('create_linux_users','db_host')
itldb=config.get('create_linux_users','db')
itldb_user=config.get('create_linux_users','db_user')
itldb_password=config.get('create_linux_users','db_password')
# Zabbix API configuration | настройки подключения к Zabbix API
zapi_host='priv.zabbix.itlogic.pro'
zapi_user='Admin'
zapi_password='Questions' 
Hostname=os.uname()[1]
serv_list=[]
Template_list=['Linux'] # There is default template linux, If there 
HostMetadata = "" # Define variable for store metadata of host
#check which OS is used
syslog.syslog('Check what platform is used')
dist,ver,rest=platform.dist()
if dist=='centos':
  # check instlled zabbix agent or no
  syslog.syslog('Get yum base and check weather zabbix-agent is alredy installed')
  import yum
  yb=yum.YumBase()
  if not yb.isPackageInstalled('zabbix-agent'):
    try:
        syslog.syslog('Zabbix agent is not installed yet, insalling...')
        yb.install(name='zabbix-agent')
        yb.processTransaction()
    except:
        syslog.syslog("Sorry, package installation failed [{err}]".format(err=str(arg)))
elif dist=='debian':
    # check installed zabbix agent 
    syslog.syslog('Get apt base and check weather zabbix-agent is alredy installed')
    import apt
    pkg_name="zabbix-agent"
    mysqldb_mod_py='python-mysqldb'
    cache=apt.cache.Cache()
    cache.update()
    pkg=cache[pkg_name]
    pkg2=cache[mysqldb_mod_py]
    if pkg.is_installed:
        syslog.syslog("{pkg_name} already installed".format(pkg_name=pkg_name))
    elif pkg2.is_installed:
        syslog.syslog("{pkg_name} already installed".format(pkg_name=mysqldb_mod_py))
    else:
        syslog.syslog('Zabbix agent is not installed yet, insalling...')
        pkg.mark_install()
        pkg2.mark_install()
        try:
            cache.commit()
        except Exception, arg:
            syslog.syslog("Sorry, package installation failed [{err}]".format(err=str(arg)))
#connect to database for getting metadata for current host
try:
    import MySQLdb
    con=MySQLdb.connect(host=itldb_host, user=itldb_user, passwd=itldb_password, db=itldb)
    cur=con.cursor()
    cur.execute('SET NAMES `utf8`')
    cur.execute('SELECT s.domain,st.type_name FROM servers s JOIN serv_matrix sm ON s.id=sm.servers_id JOIN servers_types st ON sm.servers_types_id=st.id;"')
    res=cur.fetchall()
    for row in res:
        serv_list.append({'server_name':row[0],'service':row[1]})
except MySQLdb.Error:
    syslog.syslog(syslog.LOG_ERR, con.error())
# Parse database output
for i in serv_list:
    if i['server_name'].split('.')[0]==Hostname:
        HostMetadata="Linux %s" % i['service']
        Template_list.append(i['service'])
#generate config for zabbix agent
conf="""
############ GENERAL PARAMETERS #################
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
# DebugLevel=3
# EnableRemoteCommands=0
# LogRemoteCommands=0
##### Passive checks related ####################
Server=%s
# ListenPort=10050
# ListenIP=0.0.0.0
# StartAgents=3
##### Active checks related ####################
ServerActive=%s
Hostname=%s
# RefreshActiveChecks=120
# BufferSend=5
# BufferSize=100
# MaxLinesPerSecond=100
############ ADVANCED PARAMETERS #################
# Timeout=3
# AllowRoot=0
Include=/etc/zabbix/zabbix_agentd.d/
####### USER-DEFINED MONITORED PARAMETERS #######
# UnsafeUserParameters=0
# UserParameter=
####### LOADABLE MODULES ########################
# LoadModule=
HostMetadata=%s
""" % (Zserver,ZserverActive,Hostname,HostMetadata)
# Write configuration to tempory file location for comparison
syslog.syslog('Generated conf and store it temporary for comartison')
fh = open('/tmp/zabbix_agentd.conf','w')
fh.write(conf)
fh.close()
if cmp('/tmp/zabbix_agentd.conf','/etc/zabbix/zabbix_agentd.conf'):
    syslog.syslog('Zabbix-agent configuration file has no changes')
else: 
    # Do backup of the zabbix agent configuration file
    copy2('/etc/zabbix/zabbix_agentd.conf','/etc/zabbix/zabbix_agentd.conf.backup')
    copy2('/tmp/zabbix_agentd.conf','/etc/zabbix/zabbix_agentd.conf')
    os.system('/etc/init.d/zabbix-agent restart')
# do things with zabbix api for mainteinace of tempaltes on host.
syslog.syslog('Try to connect to Zabbix API and get list of users')
# Connecting to Zabbix API
zapi=ZabbixAPI(server='http://'+zapi_host, path="")
try: 
    zapi.login(zapi_user, zapi_password)
except:
    syslog.syslog("Cannot connect to Zabbix with API call")
# Get Host ID for current host
hostid=zapi.host.get({'search':{'host':Hostname}})[0]['hostid']
if hostid:
    # Search template IDs
    templateids=[]
    for one in Template_list:
        tmplid=zapi.template.get({'search':{'host':one}})[0]['templateid']
        templateids.append(tmplid)
    # Get current templates
    NeedTmplUpdate=0 
    get_templates=zapi.template.get({'hostids':hostid})
    for i in get_templates:
        if i['templateid'] not in templateids:
            templateids.append(i['templateid'])
            NeedTmplUpdate=1
    # If there is new templates to apply, then we'll update the host
    if NeedTmplUpdate:
        syslog.syslog('Adding new templates to host')
        zapi.host.update({'hostid':hostid,'templates':templateids})
    else:
        syslog.syslog('There is no any additional template')
else:
    syslog.syslog("Host is not exist in Zabbix configuration")