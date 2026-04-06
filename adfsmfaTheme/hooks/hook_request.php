<?php
/**
 * Executed for **every** HTTP request that reaches SimpleSAMLphp.
 * We only act when ADFS posts its AuthnRequest.
 */
if ($_SERVER['REQUEST_METHOD'] === 'POST'
    && isset($_POST['SAMLRequest'], $_POST['Context'], $_POST['AuthMethod'])
) {
    $session = \SimpleSAML\Session::getSessionFromRequest();
    $session->setData('adfs_mfa', 'Context',    $_POST['Context']);
    $session->setData('adfs_mfa', 'AuthMethod', $_POST['AuthMethod']);
}