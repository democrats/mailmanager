import json
from email.Utils import parseaddr
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

needs_userdesc = dict(AddMember=True, ApprovedAddMember=True)
needs_save = dict(AddMember=True, ApprovedAddMember=True,
                  DeleteMember=True, ApprovedDeleteMember=True)

def command(mlist, cmd, *args):
    result = {}
    try:
        method = getattr(mlist, cmd)
        if needs_userdesc.get(cmd, False):
            result['return'] = method(userdesc_for(args[0]))
        else:
            result['return'] = method(*args)
        if needs_save.get(cmd, False):
            mlist.Save()
    except TypeError as err:
        error_msg = '%s' % err
        print json.dumps({'error': error_msg})
    except AttributeError as err:
        error_msg = 'AttributeError: %s' % err
        print json.dumps({'error': error_msg})
    except Errors.MMSubscribeNeedsConfirmation as err:
        print json.dumps({'result': 'pending_confirmation'})
    except Errors.MMAlreadyAMember as err:
        print json.dumps({'result': 'already_a_member'})
    except Errors.MMNeedApproval as err:
        print json.dumps({'result': 'needs_approval'})
    except Exception as err:
        error_msg = '%s: %s' % (type(err), err)
        print json.dumps({'error': error_msg})
    else:
        result['result'] = 'success'
        print json.dumps(result)

#def loadlist(mlist, jsonlist):
    #newlist = json.loads(jsonlist)
    #for attr in newlist:
        #print "Setting %s to %s" % (attr, newlist[attr])

