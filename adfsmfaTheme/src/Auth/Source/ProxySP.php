<?php
namespace SimpleSAML\Module\adfsmfaTheme\Auth\Source;

use SimpleSAML\Module\saml\Auth\Source\SP;
use SimpleSAML\Error\Error;

class ProxySP extends SP
{
    public function authenticate(array &$state): never
    {
        $session = \SimpleSAML\Session::getSessionFromRequest();
        // Capture ADFS MFA parameters on incoming AuthnRequest
        if (null !== $_POST['Context']) {
            $state['adfs:Context'] = $_POST['Context'];
            $session->setData('adfs_mfa', 'Context',    $_POST['Context']);
        }
        if (null !== $_POST['AuthMethod']) {
            $state['adfs:AuthMethod'] = $_POST['AuthMethod'];
            $session->setData('adfs_mfa', 'AuthMethod', $_POST['AuthMethod']);
        }
        // Continue with normal SAML SP authentication (redirect to real IdP)
        parent::authenticate($state);
    }
}
