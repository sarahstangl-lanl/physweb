package ShopDb::Widget::Field::FileManager;

use Moose::Role;
use HTML::Entities;
with 'HTML::FormHandler::Widget::Field::Role::HTMLAttributes';

sub render {
    my ( $self, $result ) = @_;
    my $m = HTML::Mason::Request->instance or die 'No mason';

    $result ||= $self->result;

    my $job_id = $self->form->item ? $self->form->item->job_id : '';
    my @job_attachments = $self->form->item ? $self->form->item->job_attachments : ();

    my $output = $m->scomp('/mason/ajax/jsload.comp', file => 'multi_upload.js');

    $output .= '<div style="margin: 6px 0 5px 0; max-width: 325px; max-height: 240px; overflow: -moz-scrollbars-vertical; overflow-x: hidden; overflow-y: auto;" id="shopdb-job-attachments">';

    if (!@job_attachments) {
        my $message;
        if ($self->form->item) {
            $message = "None";
        }
        else {
            $message = "You must save the job before files can be attached";
        }
        $output .= '<div id="shopdb-job-attachment-none">' . $message . '</div>';
    }

    $output .= "</div>";

    if ($self->has_auth) {
        $output .= <<END
<div style="font-weight: bold; background: #eeeeee;">Attach file</div>
<div><input type="file" id="attachmentInput" name="file" /></div>
<script type="text/javascript"><!--
    this.uploader = new MultiUpload( 'attachmentInput', {
        'action': '/resources/shopdb/upload_file.html?job_id=$job_id',
        'name_suffix_template': '',
        'show_filename_only': true,
        'onAdd': function (args) {
            //console.log('onAdd', args);
        },
        'onUploadComplete' : function (args) {
            //console.log('onUploadComplete', args);
        },
        'onUploadFail': function (args) {
            //console.log('onUploadFail', args);
        },
        'showUploadList': false
    });
--></script>
END
;
    }

    if (@job_attachments) {
        $output .= "<script language=\"javascript\">\n";
        for my $attachment (map { $_->attachment } @job_attachments) {
            my $filename = $attachment->filename;
            my $attachment_id = $attachment->attachment_id;
            $output .= "job.addAttachment('" . $attachment->filename . "', " . $attachment->attachment_id . ");\n";
        }
        $output .= '</script>';
    }

    $output = $self->wrap_field( $result, $output );

    return $output;

}

use namespace::autoclean;

1;
