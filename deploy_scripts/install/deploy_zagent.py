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
service_dict = {'linux':'Template OS Linux', 'MySQL':'Template App MySQL','Asterisk':'Template App Asterisk',\
                'Logic_CRM':'Template App Logic CRM','Centos_repo':'Template App Centos Repo',\
                'test_servers':'Template test servers','DokuWiki':'Template App Dokuwiki',\
                'Sipbalancer':'Template App Sipbalanser','OpenVZ':'Template App OpenVZ','OpenVZ_centos':'Template App OpenVZ centos'}
# Zabbix API configuration | настройки подключения к Zabbix API
zapi_host='priv.zabbix.itlogic.pro'
zapi_user='Admin'
zapi_password='Questions' 
Hostname=os.uname()[1]
LogFile='/var/log/zabbix/zabbix_agentd.log' 
Include_dir_userparam='/etc/zabbix/zabbix_agentd.d/'
Zserver=zapi_host #Fix this in case of separate frontend and zabbix server
ZserverActive=Zserver
serv_list=[]
proj_list=[]
Template_list=['linux'] # There is default template linux, If there 
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
    if pkg.is_installed and pkg2.is_installed:
        syslog.syslog("{pkg_name} already installed".format(pkg_name=pkg_name))
    else:
        syslog.syslog('Zabbix agent is not installed yet, insalling...')
        pkg.mark_install()
        if pkg2.is_installed:
            syslog.syslog("{pkg_name} already installed".format(pkg_name=mysqldb_mod_py))
        else:
            pkg2.mark_install()
        try:
            cache.commit()
            syslog.syslog("Installed")
        except Exception, arg:
            syslog.syslog("Sorry, package installation failed [{err}]".format(err=str(arg)))
    # Defune logfile location
    LogFile="/var/log/zabbix-agent/zabbix_agentd.log"
    #Define Zabbix agent UserParameter directory
    Include_dir_userparam='/etc/zabbix/zabbix_agentd.conf.d/'
#connect to database for getting metadata for current host
try:
    import MySQLdb
    con=MySQLdb.connect(host=itldb_host, user=itldb_user, passwd=itldb_password, db=itldb)
    cur=con.cursor()
    cur.execute('SET NAMES `utf8`')
    cur.execute('SELECT s.domain,st.type_name \
                        FROM servers s \
                        JOIN serv_matrix sm ON s.id=sm.servers_id \
                        JOIN servers_types st ON sm.servers_types_id=st.id;')
    res=cur.fetchall()
    for row in res:
        serv_list.append({'server_name':row[0],'service':row[1]})
    # get project/server matrix
    cur.execute('SELECT s.domain,p.project_name \
                 FROM servers s \
                 JOIN project_matrix pm ON s.id=pm.servers_id \
                 JOIN projects p ON p.id=pm.projects_id;')
    proj=cur.fetchall()
    for row in proj:
        proj_list.append({'server_name':row[0],'project':row[1]})
except MySQLdb.Error:
    syslog.syslog(syslog.LOG_ERR, con.error())
# Parse database output
for server in serv_list:
    if server['server_name'].split('.')[0]==Hostname:
        HostMetadata="linux %s" % server['service']
        Template_list.append(server['service'])
    else:
        HostMetadata="linux"
for srv in proj_list:
    if srv['server_name'].split('.')[0]==Hostname:
        hostgroup.append(srv['project'])   

#generate config for zabbix agent
conf="""
############ GENERAL PARAMETERS #################
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=%s
LogFileSize=10
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
Include=%s
####### USER-DEFINED MONITORED PARAMETERS #######
# UnsafeUserParameters=0
# UserParameter=
####### LOADABLE MODULES ########################
# LoadModule=
HostMetadata=%s
""" % (LogFile,Zserver,ZserverActive,Hostname,Include_dir_userparam,HostMetadata)
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
hostid=zapi.host.get({'search':{'host':Hostname}})
if hostid: #check if we get any data from call
    hostid=hostid[0]['hostid']
    # Search template IDs
    templateids=[]
    for one in Template_list:
        try:
            tmplget=zapi.template.get({'search':{'host':service_dict[one]}})
        except KeyError:
            syslog.syslog('Template with name %s is not exsit' % service_dict[one])
            tmplget = zapi.template.get({'search': {'host': one}})
        if not tmplget:
            syslog.syslog('Template is not found, let\'s create empty one with necessary name')
            newtmpl = zapi.template.create({"host": service_dict[one], "groups": {"groupid": 1}})
        else:
            for i in tmplget:
                tmpldic = {} # clean dic otherwise it won't be updated
                tmpid=i['templateid'] # select it from JSON output
                tmpldic['templateid']= tmpid # store temporary it in dictionary
                templateids.append(tmpldic) # add it to template list
    # Get current templates
    NeedTmplUpdate=0 
    get_htemplates=zapi.template.get({'hostids':hostid})
    if get_htemplates:
        for i in get_htemplates:
            for j in templateids:
                if i['templateid'] not in j['templateid']:
                    NeedTmplUpdate=1
    # If there is new templates to apply, then we'll update the host
    elif templateids:
        NeedTmplUpdate=1
    if NeedTmplUpdate:
        syslog.syslog('Adding new templates to host')
        zapi.host.update({'hostid':hostid,'templates':templateids})
    else:
        syslog.syslog('There is no any additional template')
else:
    syslog.syslog("Host is not exist in Zabbix configuration")