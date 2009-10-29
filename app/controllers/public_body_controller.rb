# app/controllers/body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body_controller.rb,v 1.4 2009-07-14 23:30:37 francis Exp $

class PublicBodyController < ApplicationController
    # XXX tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
    def show
        if MySociety::Format.simplify_url_part(params[:url_name]) != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name])
            return
        end

        @public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
        raise "None found" if @public_body.nil? # XXX proper 404

        # If found by historic name, redirect to new name
        redirect_to show_public_body_url(:url_name => @public_body.url_name) if 
            @public_body.url_name != params[:url_name]

        set_last_body(@public_body)

        top_url = main_url("/")
        @searched_to_send_request = false
        referrer = request.env['HTTP_REFERER']
        if !referrer.nil? && referrer.match(%r{^#{top_url}search/.*/bodies$})
            @searched_to_send_request = true
        end

        # Use search query for this so can collapse and paginate easily
        # XXX really should just use SQL query here rather than Xapian.
        begin
            @xapian_requests = perform_search([InfoRequestEvent], 'requested_from:' + @public_body.url_name, 'newest', 'request_collapse')
            if (@page > 1)
                @page_desc = " (page " + @page.to_s + ")" 
            else    
                @page_desc = ""
            end
        rescue
            @xapian_requests = nil
        end

        @track_thing = TrackThing.create_track_for_public_body(@public_body)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]
    end

    def view_email
        @public_bodies = PublicBody.find(:all, :conditions => [ "url_name = ?", params[:url_name] ])
        @public_body = @public_bodies[0]

        if params[:submitted_view_email]
            if verify_recaptcha
                flash.discard(:error)
                render :template => "public_body/view_email"
                return
            end
            flash.now[:error] = "There was an error with the words you entered, please try again."
        end
        render :template => "public_body/view_email_captcha"
    end

    def list
        @tag = params[:tag]
        
        # FIXME untangle this unholy mess
        if @tag.nil?
            @tag = "all"
            @public_bodies = PublicBody.paginate(
                :order => "public_bodies.name", :page => params[:page], :per_page => 1000 # fit all councils on one page
                )
        else
            if @tag.size == 1
                @tag.upcase!
                @public_bodies = PublicBody.paginate(
                    :order => "public_bodies.name", :page => params[:page], :per_page => 1000, # fit all councils on one page
                    :conditions => ['first_letter = ?', @tag])              
            else
                if @tag == 'other'
                    category_list = PublicBody.categories
                    @public_bodies = PublicBody.tagged_with(category_list, :exclude => true).paginate(
                    :order => "public_bodies.name", :page => params[:page], :per_page => 1000 # fit all councils on one page
                    )
                else
                    @public_bodies = PublicBody.tagged_with(@tag, :on => :tags).paginate(
                    :order => "public_bodies.name", :page => params[:page], :per_page => 1000 # fit all councils on one page
                    )
                end
            end             
        end
            
        if @tag.size == 1
            @description = "beginning with '" + @tag + "'"
        else
            @description = PublicBody.categories_by_tag[@tag]
            if @description.nil?
                @description = @tag
            end
        end

        cache_in_squid
    end
end

