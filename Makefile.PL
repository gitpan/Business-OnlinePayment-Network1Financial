use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::Network1Financial',
    'VERSION_FROM' => 'Network1Financial.pm', # finds $VERSION
    'AUTHOR'       => 'Ivan Kohler <ivan-network1financial@420.am>',
    #'NORECURS'     => 1, # dont descend into subdirectories
    'PREREQ_PM'    => { 'Net::SSLeay' => '0',
                        #'Text::CSV_XS' => 0,
                        'Business::OnlinePayment' => '0',
                        #'Business::CreditCard' => 0.27,
                      },
);

