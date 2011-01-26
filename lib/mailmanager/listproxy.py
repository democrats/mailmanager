import json
from email.Utils import parseaddr
from collections import Callable
from Mailman import MailList
from Mailman import Errors

class MailingListEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, MailList.MailList):
            return {'name': obj.internal_name()}
        return json.JSONEncoder.default(self, obj)

def dumplist(mlist):
    print json.dumps(mlist, True, cls=MailingListEncoder)

class UserDesc: pass
def userdesc_for(member):
    userdesc = UserDesc()
    userdesc.fullname, userdesc.address = parseaddr(member)
    return userdesc

def unwindattrs(obj, attrs, *args):
    if not attrs.count('.'):
        attr = getattr(obj, attrs)
        if isinstance(attr, Callable):
            return attr(*args)
        else:
            return attr
    else:
        attr, nextattrs = attrs.split('.', 1)
        nextobj = getattr(obj, attr)
        return unwindattrs(nextobj, nextattrs, *args)

needs_userdesc = dict(AddMember=True, ApprovedAddMember=True)
needs_save = dict(AddMember=True, ApprovedAddMember=True,
                  DeleteMember=True, ApprovedDeleteMember=True,
                  moderator_append=True, moderator_remove=True)

def command(mlist, cmd, *args):
    result = {}
    try:
        if needs_save.get(cmd.replace('.','_'), False):
            mlist.Lock()
        if needs_userdesc.get(cmd, False):
            result['return'] = unwindattrs(mlist, cmd, userdesc_for(args[0]))
        else:
            result['return'] = unwindattrs(mlist, cmd, *args)
        if needs_save.get(cmd.replace('.','_'), False):
            mlist.Save()
    except TypeError, err:
        error_msg = '%s' % err
        print json.dumps({'error': error_msg})
    except AttributeError, err:
        error_msg = 'AttributeError: %s' % err
        print json.dumps({'error': error_msg})
    except Errors.MMSubscribeNeedsConfirmation, err:
        print json.dumps({'result': 'pending_confirmation'})
    except Errors.MMAlreadyAMember, err:
        print json.dumps({'result': 'already_a_member'})
    except Errors.MMNeedApproval, err:
        print json.dumps({'result': 'needs_approval'})
    except Exception, err:
        error_msg = '%s: %s' % (type(err), err)
        print json.dumps({'error': error_msg})
    else:
        result['result'] = 'success'
        print json.dumps(result)

#def loadlist(mlist, jsonlist):
    #newlist = json.loads(jsonlist)
    #for attr in newlist:
        #print "Setting %s to %s" % (attr, newlist[attr])

