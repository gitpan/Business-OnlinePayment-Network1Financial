package Business::OnlinePayment::Network1Financial;

use strict;
use Carp;
use Business::OnlinePayment;
#use Business::CreditCard;
use Net::SSLeay qw( make_form post_https make_headers );
use URI;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.02';

$DEBUG = 0;

#my %error = (
#  000000 => 'INTERNAL SERVER ERROR',
#  000001 => 'INTERNAL SERVER ERROR',
#  000002 => 'INTERNAL SERVER ERROR',
#  900000 => 'INVALID T_ORDERNUM',
#  900001 => 'INVALID C_NAME',
#  900002 => 'INVALID C_ADDRESS',
#  900003 => 'INVALID C_CITY',
#  900004 => 'INVALID C_STATE',
#  900005 => 'INVALID C_ZIP',
#  900006 => 'INVALID C_COUNTRY',
#  900007 => 'INVALID C_TELEPHONE',
#  900008 => 'INVALID C_FAX',
#  900009 => 'INVALID C_EMAIL',
#  900010 => 'INVALID C_SHIP_NAME',
#  900011 => 'INVALID C_SHIP_ADDRESS',
#  900012 => 'INVALID C_SHIP_CITY',
#  900013 => 'INVALID C_SHIP_STATE',
#  900014 => 'INVALID C_SHIP_ZIP',
#  900015 => 'INVALID C_SHIP_COUNTRY',
#  900016 => 'INVALID C_CARDNUMBER',
#  900017 => 'INVALID C_EXP',
#  900018 => 'INVALID C_CVV',
#  900019 => 'INVALID T_AMT',
#  900020 => 'INVALID T_CODE',
#  900021 => 'INVALID T_AUTH',
#  900022 => 'INVALID T_REFERENCE',
#  900023 => 'INVALID T_TRACKDATA',
#  900024 => 'INVALID T_TRACKING_NUMBER',
#  900025 => 'INVALID T_CUSTOMER_NUMBER',
#  910000 => 'SERVICE NOT ALLOWED',
#  910001 => 'VISA NOT ALLOWED',
#  910002 => 'MASTERCARD NOT ALLOWED',
#  910003 => 'AMEX NOT ALLOWED',
#  910004 => 'DISCOVER NOT ALLOWED',
#  910005 => 'CARD TYPE NOT ALLOWED',
#  911911 => 'SECURITY VIOLATION',
#  920000 => 'ITEM NOT FOUND',
#  920001 => 'CREDIT VOL EXCEEDED',
#  920002 => 'AVS FAILURE',
#  999999 => 'INTERNAL SERVER ERROR',
#);

sub set_defaults {
    my $self = shift;
    $self->server('va.eftsecure.net');
    $self->port('443');
    #$self->path('/cgi-bin/eftBankcard.dll?transaction');
    #$self->build_subs(qw( product_id merchant_id ));
}

sub map_fields {
    my $self = shift;
    my %content = $self->content();

    # ACTION MAP
    my %actions = ( 'normal authorization' => '01',
                    'authorization only'   => '02',
                    'credit'               => '06',
                    'post authorization'   => '03',
                  );
    $content{'action'} = $actions{lc($content{'action'})} || $content{'action'};

    # TYPE MAP
    my %types = ('visa'               => 'BankCard',
                 'mastercard'         => 'BankCard',
                 'american express'   => 'BankCard',
                 'discover'           => 'BankCard',
                 'cc'                 => 'BankCard',
                 'check'              => 'VirtualCheck',
                );
    $content{'type'} = $types{lc($content{'type'})} || $content{'type'};
    $self->transaction_type($content{'type'});

    # stuff it back into %content
    $self->content(%content);
}

sub revmap_fields {
    my($self, %map) = @_;
    my %content = $self->content();
    foreach(keys %map) {
        $content{$_} = ref($map{$_})
                         ? ${ $map{$_} }
                         : $content{$map{$_}};
    }
    $self->content(%content);
}

sub submit {
    my $self = shift;
    $self->map_fields();
    my %content = $self->content();

    my $action = lc($content{'action'});
    if ( $action eq '01' ) {
    } else {
      croak "$action not (yet) supported";
    }
    
    my $type = $content{'type'};
    if ( $type eq 'BankCard' ) {
    } else {
      croak "$type not (yet) supported";
    }

    $content{'expiration'} =~ /^(\d+)\/(\d+)$/;
    my($m, $y) = ($1, $2);
    $m = $m+0;
    $m = "0$m" if $m<10;
    my $exp = "$m$y";

    $self->revmap_fields(
        'M_id'              => 'login',
        'M_key'             => 'password',
        'C_name'            => 'name',
        'C_address'         => 'address',
        'C_city'            => 'city',
        'C_state'           => 'state',
        'C_zip'             => 'zip',
        'C_country'         => 'country',
        'C_email'           => 'email',
        'C_cardnumber'      => 'card_number',
        'C_exp'             => \$exp,
        'T_amt'             => 'amount',
        'T_code'            => 'action',
        #'T_ordernum'        => 'invoice_number', #probably not unique...
        #'T_auth'            =>
        #'T_trackdata'       =>
        'C_cvv'             => 'cvv',
        'T_customer_number' => 'customer_id',
        #'T_tax'             =>
        #'T_shipping'        =>
        #'C_ship_name'       =>
        #'C_ship_address'    =>
        #'C_ship_city'       =>
        #'C_ship_state'      =>
        #'C_ship_zip'        =>
        #'C_ship_country'    =>
        'C_telephone'       => 'phone',
        #'C_fax'             => 'fax',
    );

    my %post_data = $self->get_fields(qw(
        M_id M_key C_name C_address C_city C_state C_zip C_country C_email
        C_cardnumber C_exp T_amt T_code
        C_cvv T_customer_number
        C_telephone
    ));
        #T_ordernum T_auth T_trackdata
        #T_tax T_shipping C_ship_name C_ship_address C_ship_city C_ship_state
        #C_ship_zip C_ship_country
        #C_fax

    my $pd = make_form(%post_data);
    my $s = $self->server();
    my $p = $self->port();
    my $t = "/cgi-bin/eft$type.dll?transaction";
    my($page,$server_response,%headers) = post_https($s,$p,$t,'',$pd);

    my $approved = substr($page,1, 1); #A is approved E is declined/error.
    my $result_code = substr($page, 2, 6);
    my $error_message = substr($page, 8, 32);
    #print "Front-End Indicator: " . substr($page, 40, 2);
    #print "CVV Indicator: " . substr($page, 42, 1);
    #print "AVS Indicator: " . substr($page, 43, 1);
    #print "Risk Indicator: " . substr($page, 44, 2);
    my $reference = substr($page, 46, 10);
    #print "Order Number: " . substr($page, index($page, chr(28)) + 1,
    #                      rindex($page, chr(28)) - index($page, chr(28)) - 1);

    if ( $approved eq 'A' ) {
      $self->is_success(1);
      $self->result_code($result_code);
      $self->error_message($error_message);
      $self->authorization($reference);
    } else {
      $self->is_success(0);
      $self->result_code($result_code);
      $self->error_message($error_message);
    }

}

1;
__END__

=head1 NAME

Business::OnlinePayment::Network1Financial - Network1 Financial backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("Network1Financial");
  $tx->content(
      type           => 'CC',
      login          => 'test', #12 Digit ID Number
      password       => 'test', #12 Digit Security Key
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      name           => 'Tofu Beast',
      card_number    => '4007000000027',
      expiration     => '09/02',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

This module only implements credit card trasactions at this time.  Electronic
check (ACH) transactions are not (yet) supported.

=head1 COMPATIBILITY

This module implements the interface documented at
https://va.eftsecure.net/VirtualTerminal/Documentation/

=head1 AUTHOR

Ivan Kohler <ivan-network1financial@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>

=cut

