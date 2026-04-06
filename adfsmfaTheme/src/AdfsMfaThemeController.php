<?php

namespace SimpleSAML\Module\adfsmfaTheme;

use SimpleSAML\XHTML\TemplateControllerInterface;
use SimpleSAML\Session;

class AdfsMfaThemeController implements TemplateControllerInterface
{
    public function setUpTwig(\Twig\Environment &$twig): void
    {
        // No need to modify Twig itself for this use case
    }

    public function display(array &$data): void
    {
        $session = Session::getSessionFromRequest();
        $data['session'] = $session;
        // Add Context and AuthMethod to the post array if available in state
        if (isset($data['state']['adfs:Context']) and isset($data['state']['adfs:AuthMethod'])) {
            $data['post']['_SAMLResponse'] = $data['post']['SAMLResponse'];
            unset($data['post']['SAMLResponse']);
            $data['post']['Context'] = $data['state']['adfs:Context'];
            $data['post']['AuthMethod'] = $data['state']['adfs:AuthMethod'];
        }
    }
}
