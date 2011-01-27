try:
    import json
except ImportError:
    import simplejson as json
from email.Utils import parseaddr
try:
    from collections import Callable
except ImportError:
    def iscallable(attr):
        return callable(attr)
else:
    def iscallable(attr):
        return isinstance(attr, Callable)
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

def unwindattrs(obj, attrname, *args):
    if not attrname.count('.'):
        attr = getattr(obj, attrname)
        if iscallable(attr):
            return attr(*args)
        else:
            if len(args) > 0:
                # must be a setter
                setattr(obj, attrname, args[0])
            else:
                # must be a getter
                return attr
    else:
        attr, nextattrname = attrname.split('.', 1)
        nextobj = getattr(obj, attr)
        return unwindattrs(nextobj, nextattrname, *args)

needs_userdesc = dict(AddMember=True, ApprovedAddMember=True)
needs_save = dict(AddMember=True, ApprovedAddMember=True,
                  DeleteMember=True, ApprovedDeleteMember=True,
                  moderator_append=True, moderator_remove=True)
needs_save_with_arg = dict(description=True, subject_prefix=True)

def command(mlist, cmd, *args):
    result = {}
    try:
        if (needs_save.get(cmd.replace('.','_'), False) or
            (needs_save_with_arg.get(cmd.replace('.','_'), False) and
            len(args) > 0)):
                mlist.Lock()
        if needs_userdesc.get(cmd, False):
            result['return'] = unwindattrs(mlist, cmd, userdesc_for(args[0]))
        else:
            result['return'] = unwindattrs(mlist, cmd, *args)
        if (needs_save.get(cmd.replace('.','_'), False) or
            (needs_save_with_arg.get(cmd.replace('.','_'), False) and
            len(args) > 0)):
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

