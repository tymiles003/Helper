# The CloudRecorder is a software appliance operated by SightCall.  It can archive and transcode
# recordings.  Use of the service requires an enterprise account.

class CloudrecorderController < ApplicationController

  # The receiver is unauthenticated and unverified
  skip_before_action :authorize, :only => :receiver
  skip_before_action :verify_authenticity_token, :only => :receiver

  #
  # The CloudRecorder posts to this callback url.  Update the ticket
  # with this information by remote_key.
  #

  def receiver

    Logger.info "CR RECEIVER:#{params.inspect}"
    ticket = Ticket.find_by_key(params['remote_key'])

    if ticket
      Logger.info "CR RECEIVER: updating ticket" 
      ticket.update_attributes(:cr_id => params['id'],
                               :cr_title => params['title'],
                               :cr_status => params['status'],
                               :cr_webm_duration => params['webm_duration'],
                               :cr_webm_s3url => params['webm_s3url'],
                               :cr_mp4_duration => params['mp4_duration'],
                               :cr_mp4_s3url => params['mp4_s3url'],
                               :cr_vb_state => params['vb_state'],
                               :cr_vb_fileurl => params['vb_fileurl']
                               )

    else
      Logger.info "CR RECEIVER: ticket not found by remote key"
    end

    # Send back to the cloud recorder
    render :json => { :ok => "receiver ok" }
  end
 

  #
  # Post a request to the Cloudrecorder to allocate a slot for a new recording
  #

  def recording
    if CLOUDRECORDER_TOKEN
      begin
        response = RestClient.post("#{CLOUDRECORDER_BASE}/recordings", { }, 'authorization' => "Token token=#{CLOUDRECORDER_TOKEN}")
        jdata = JSON.parse(response.body)
        # puts "J:#{jdata}"
        render :json => {
          :id => jdata["id"],
          :upload_key => jdata["upload_key"]
        }
      rescue => e
        render :json => {
          :error => e.message
        }
      end
    else
      render :json => { :error => "CloudRecorder not configured" }
    end
  end

  #
  # Request the Detail of a Recording by ID.  Format is JSON.
  #

  def detail

    begin
      response = RestClient.get("#{CLOUDRECORDER_BASE}/recordings/#{params[:id]}", 'authorization' => "Token token=#{CLOUDRECORDER_TOKEN}")
      jdata = JSON.parse(response.body)

      # puts "J:#{jdata}"

      # return only those fields necessary ?
      render :json => {
        :id => jdata["id"],
        :status => jdata["status"],
        :webm_duration => jdata["webm_duration"],
        :webm_s3url => jdata["webm_s3url"],
        :mp4_duration => jdata["mp4_duration"],
        :mp4_s3url => jdata["mp4_s3url"],
        :vb_mediaid => jdata["vb_mediaid"],
        :vb_fileurl => jdata["vb_fileurl"]
      }
    rescue => e
      render :json => {
        :error => e.message
      }
    end
  end
    
end
