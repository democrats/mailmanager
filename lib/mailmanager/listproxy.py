import json
from Mailman import MailList

class MailingListEncoder(json.JSONEncoder):
  def default(self, obj):
    if isinstance(obj, MailList.MailList):
      return {'name': obj.internal_name()}
    return json.JSONEncoder.default(self, obj)

def dumplist(mlist):
  print json.dumps(mlist, True, cls=MailingListEncoder)

def command(mlist, cmd, *args):
  try:
    method = getattr(mlist, cmd)
    print json.dumps(method(*args))
  except TypeError as err:
    error_msg = '%s' % err
    print json.dumps({'error': error_msg})
  except AttributeError as err:
    error_msg = '%s is not a valid command; must be a MailList method' % err
    print json.dumps({'error': error_msg})

#def loadlist(mlist, jsonlist):
  #newlist = json.loads(jsonlist)
  #for attr in newlist:
    #print "Setting %s to %s" % (attr, newlist[attr])

