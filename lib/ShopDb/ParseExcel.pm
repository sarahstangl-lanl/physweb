package ShopDb::ParseExcel;

use strict;
use warnings;

use base 'Spreadsheet::ParseExcel::SaveParser';

sub new {
    my ($class, %params) = @_;
    $class->SUPER::new(%params);
}

# Modified version of SaveAs method from Spreadsheet::ParseExcel::SaveParser::Workbook
# that allows leading zeros to be preserved
sub save {
    my ( $self, $oBook, $sName ) = @_;

    # Create a new Excel workbook
    my $oWrEx = Spreadsheet::WriteExcel->new($sName);
    unless ($oWrEx) {
        warn "Failed to open spreadsheet $sName: $!";
        return undef;
    }
    $oWrEx->compatibility_mode();
    my %hFmt;

    my $iNo  = 0;
    my @aAlH = (
        'left', 'left',    'center', 'right',
        'fill', 'justify', 'merge',  'equal_space'
    );
    my @aAlV = ( 'top', 'vcenter', 'bottom', 'vjustify', 'vequal_space' );

    foreach my $pFmt ( @{ $oBook->{Format} } ) {
        my $oFmt = $oWrEx->addformat();    # Add Formats
        unless ( $pFmt->{Style} ) {
            $hFmt{$iNo} = $oFmt;
            my $rFont = $pFmt->{Font};

            $oFmt->set_font( $rFont->{Name} );
            $oFmt->set_size( $rFont->{Height} );
            $oFmt->set_color( $rFont->{Color} );
            $oFmt->set_bold( $rFont->{Bold} );
            $oFmt->set_italic( $rFont->{Italic} );
            $oFmt->set_underline( $rFont->{Underline} );
            $oFmt->set_font_strikeout( $rFont->{Strikeout} );
            $oFmt->set_font_script( $rFont->{Super} );

            $oFmt->set_hidden( $rFont->{Hidden} );    #Add

            $oFmt->set_locked( $pFmt->{Lock} );

            $oFmt->set_align( $aAlH[ $pFmt->{AlignH} ] );
            $oFmt->set_align( $aAlV[ $pFmt->{AlignV} ] );

            $oFmt->set_rotation( $pFmt->{Rotate} );

            $oFmt->set_num_format(
                $oBook->{FmtClass}->FmtStringDef( $pFmt->{FmtIdx}, $oBook ) );

            $oFmt->set_text_wrap( $pFmt->{Wrap} );

            $oFmt->set_pattern( $pFmt->{Fill}->[0] );
            $oFmt->set_fg_color( $pFmt->{Fill}->[1] )
              if ( ( $pFmt->{Fill}->[1] >= 8 )
                && ( $pFmt->{Fill}->[1] <= 63 ) );
            $oFmt->set_bg_color( $pFmt->{Fill}->[2] )
              if ( ( $pFmt->{Fill}->[2] >= 8 )
                && ( $pFmt->{Fill}->[2] <= 63 ) );

            $oFmt->set_left(
                ( $pFmt->{BdrStyle}->[0] > 7 ) ? 3 : $pFmt->{BdrStyle}->[0] );
            $oFmt->set_right(
                ( $pFmt->{BdrStyle}->[1] > 7 ) ? 3 : $pFmt->{BdrStyle}->[1] );
            $oFmt->set_top(
                ( $pFmt->{BdrStyle}->[2] > 7 ) ? 3 : $pFmt->{BdrStyle}->[2] );
            $oFmt->set_bottom(
                ( $pFmt->{BdrStyle}->[3] > 7 ) ? 3 : $pFmt->{BdrStyle}->[3] );

            $oFmt->set_left_color( $pFmt->{BdrColor}->[0] )
              if ( ( $pFmt->{BdrColor}->[0] >= 8 )
                && ( $pFmt->{BdrColor}->[0] <= 63 ) );
            $oFmt->set_right_color( $pFmt->{BdrColor}->[1] )
              if ( ( $pFmt->{BdrColor}->[1] >= 8 )
                && ( $pFmt->{BdrColor}->[1] <= 63 ) );
            $oFmt->set_top_color( $pFmt->{BdrColor}->[2] )
              if ( ( $pFmt->{BdrColor}->[2] >= 8 )
                && ( $pFmt->{BdrColor}->[2] <= 63 ) );
            $oFmt->set_bottom_color( $pFmt->{BdrColor}->[3] )
              if ( ( $pFmt->{BdrColor}->[3] >= 8 )
                && ( $pFmt->{BdrColor}->[3] <= 63 ) );
        }
        $iNo++;
    }
    for ( my $iSheet = 0 ; $iSheet < $oBook->{SheetCount} ; $iSheet++ ) {
        my $oWkS = $oBook->{Worksheet}[$iSheet];
        my $oWrS = $oWrEx->addworksheet( $oWkS->{Name} );

        # Preserve leading zeros
        $oWrS->keep_leading_zeros();

        #Landscape
        if ( !$oWkS->{Landscape} ) {    # Landscape (0:Horizontal, 1:Vertical)
            $oWrS->set_landscape();
        }
        else {
            $oWrS->set_portrait();
        }

        #Protect
        if ( defined $oWkS->{Protect} )
        {    # Protect ('':NoPassword, Password:Password)
            if ( $oWkS->{Protect} ne '' ) {
                $oWrS->protect( $oWkS->{Protect} );
            }
            else {
                $oWrS->protect();
            }
        }
        if ( ( $oWkS->{FitWidth} == 1 ) and ( $oWkS->{FitHeight} == 1 ) ) {

            # Pages on fit with width and Heigt
            $oWrS->fit_to_pages( $oWkS->{FitWidth}, $oWkS->{FitHeight} );

            #Print Scale
            $oWrS->set_print_scale( $oWkS->{Scale} );
        }
        else {

            #Print Scale
            $oWrS->set_print_scale( $oWkS->{Scale} );

            # Pages on fit with width and Heigt
            $oWrS->fit_to_pages( $oWkS->{FitWidth}, $oWkS->{FitHeight} );
        }

        # Paper Size
        $oWrS->set_paper( $oWkS->{PaperSize} );

        # Margin
        $oWrS->set_margin_left( $oWkS->{LeftMargin} );
        $oWrS->set_margin_right( $oWkS->{RightMargin} );
        $oWrS->set_margin_top( $oWkS->{TopMargin} );
        $oWrS->set_margin_bottom( $oWkS->{BottomMargin} );

        # HCenter
        $oWrS->center_horizontally() if ( $oWkS->{HCenter} );

        # VCenter
        $oWrS->center_vertically() if ( $oWkS->{VCenter} );

        # Header, Footer
        $oWrS->set_header( $oWkS->{Header}, $oWkS->{HeaderMargin} );
        $oWrS->set_footer( $oWkS->{Footer}, $oWkS->{FooterMargin} );

        # Print Area
        if ( ref( $oBook->{PrintArea}[$iSheet] ) eq 'ARRAY' ) {
            my $raP;
            for $raP ( @{ $oBook->{PrintArea}[$iSheet] } ) {
                $oWrS->print_area(@$raP);
            }
        }

        # Print Title
        my $raW;
        foreach $raW ( @{ $oBook->{PrintTitle}[$iSheet]->{Row} } ) {
            $oWrS->repeat_rows(@$raW);
        }
        foreach $raW ( @{ $oBook->{PrintTitle}[$iSheet]->{Column} } ) {
            $oWrS->repeat_columns(@$raW);
        }

        # Print Gridlines
        if ( $oWkS->{PrintGrid} == 1 ) {
            $oWrS->hide_gridlines(0);
        }
        else {
            $oWrS->hide_gridlines(1);
        }

        # Print Headings
        if ( $oWkS->{PrintHeaders} ) {
            $oWrS->print_row_col_headers();
        }

        # Horizontal Page Breaks
        $oWrS->set_h_pagebreaks( @{ $oWkS->{HPageBreak} } );

        # Veritical Page Breaks
        $oWrS->set_v_pagebreaks( @{ $oWkS->{VPageBreak} } );



#        PageStart    => $oWkS->{PageStart},            # Page number for start
#        UsePage      => $oWkS->{UsePage},              # Use own start page number
#        NoColor      => $oWkS->{NoColor},               # Print in blcak-white
#        Draft        => $oWkS->{Draft},                 # Print in draft mode
#        Notes        => $oWkS->{Notes},                 # Print notes
#        LeftToRight  => $oWkS->{LeftToRight},           # Left to Right


        for (
            my $iC = $oWkS->{MinCol} ;
            defined $oWkS->{MaxCol} && $iC <= $oWkS->{MaxCol} ;
            $iC++
          )
        {
            if ( defined $oWkS->{ColWidth}[$iC] ) {
                if ( $oWkS->{ColWidth}[$iC] > 0 ) {
                    $oWrS->set_column( $iC, $iC, $oWkS->{ColWidth}[$iC] )
                      ;    #, undef, 1) ;
                }
                else {
                    $oWrS->set_column( $iC, $iC, 0, undef, 1 );
                }
            }
        }
        for (
            my $iR = $oWkS->{MinRow} ;
            defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ;
            $iR++
          )
        {
            $oWrS->set_row( $iR, $oWkS->{RowHeight}[$iR] );
            for (
                my $iC = $oWkS->{MinCol} ;
                defined $oWkS->{MaxCol} && $iC <= $oWkS->{MaxCol} ;
                $iC++
              )
            {

                my $oWkC = $oWkS->{Cells}[$iR][$iC];
                if ($oWkC) {
                    if ( $oWkC->{Merged} ) {
                        my $oFmtN = $oWrEx->addformat();
                        $oFmtN->copy( $hFmt{ $oWkC->{FormatNo} } );
                        $oFmtN->set_merge(1);
                        $oWrS->write(
                            $iR,
                            $iC,
                            $oBook->{FmtClass}
                              ->TextFmt( $oWkC->{Val}, $oWkC->{Code} ),
                            $oFmtN
                        );
                    }
                    else {
                        $oWrS->write(
                            $iR,
                            $iC,
                            $oBook->{FmtClass}
                              ->TextFmt( $oWkC->{Val}, $oWkC->{Code} ),
                            $hFmt{ $oWkC->{FormatNo} }
                        );
                    }
                }
            }
        }
    }
    return $oWrEx;
}


1;
