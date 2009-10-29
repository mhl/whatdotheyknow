# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.68 2009-08-19 23:20:39 francis Exp $

class UserController < ApplicationController
    # Show page about a user
    def show
        if MySociety::Format.simplify_url_part(params[:url_name], 32) != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name], 32)
            return
        end

        @display_user = User.find(:first, :conditions => [ "url_name = ? and email_confirmed = ?", params[:url_name], true ])
        if not @display_user
            raise "user not found, url_name=" + params[:url_name]
        end
        @same_name_users = User.find(:all, :conditions => [ "name = ? and email_confirmed = ? and id <> ?", @display_user.name, true, @display_user.id ], :order => "created_at")

        @is_you = !@user.nil? && @user.id == @display_user.id

        # Use search query for this so can collapse and paginate easily
        # XXX really should just use SQL query here rather than Xapian.
        begin
            @xapian_requests = perform_search([InfoRequestEvent], 'requested_by:' + @display_user.url_name, 'newest', 'request_collapse')
            @xapian_comments = perform_search([InfoRequestEvent], 'commented_by:' + @display_user.url_name, 'newest', nil)

            if (@page > 1)
                @page_desc = " (page " + @page.to_s + ")" 
            else    
                @page_desc = ""
            end
        rescue
            @xapian_requests = nil
            @xapian_comments = nil
        end

        # Track corresponding to this page
        @track_thing = TrackThing.create_track_for_user(@display_user)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]

        # All tracks for the user
        if @is_you
            @track_things = TrackThing.find(:all, :conditions => ["tracking_user_id = ? and track_medium = ?", @display_user.id, 'email_daily'], :order => 'created_at desc')
            @track_things_grouped = @track_things.group_by(&:track_type)
        end

        # Requests you need to describe
        if @is_you
            @undescribed_requests = @display_user.get_undescribed_requests 
        end
    end

    # Login form
    def signin
        work_out_post_redirect

        # make sure we have cookies
        if session.instance_variable_get(:@dbman)
            if not session.instance_variable_get(:@dbman).instance_variable_get(:@original)
                # try and set them if we don't
                if !params[:again]
                    redirect_to signin_url(:r => params[:r], :again => 1)
                    return
                end
                render :action => 'no_cookies'
                return
            end
        end
        # remove "cookie setting attempt has happened" parameter if there is one and cookies worked
        if params[:again]
            redirect_to signin_url(:r => params[:r], :again => nil)
            return
        end
        
        if not params[:user_signin] 
            # First time page is shown
            render :action => 'sign' 
            return
        else
            @user_signin = User.authenticate_from_form(params[:user_signin], @post_redirect.reason_params[:user_name] ? true : false)
            if @user_signin.errors.size > 0
                # Failed to authenticate
                render :action => 'sign' 
                return
            else
                # Successful login
                if @user_signin.email_confirmed
                    session[:user_id] = @user_signin.id
                    session[:user_circumstance] = nil
                    session[:remember_me] = params[:remember_me] ? true : false
                    do_post_redirect @post_redirect
                else
                    send_confirmation_mail @user_signin
                end
                return
            end
        end
    end

    # Create new account form
    def signup
        work_out_post_redirect

        # Make the user and try to save it
        @user_signup = User.new(params[:user_signup])
        if not @user_signup.valid?
            # Show the form
            render :action => 'sign'
        else
            user_alreadyexists = User.find_user_by_email(params[:user_signup][:email])
            if user_alreadyexists
                already_registered_mail user_alreadyexists
                return
            else 
                # New unconfirmed user
                @user_signup.email_confirmed = false
                @user_signup.save!

                send_confirmation_mail @user_signup
                return
            end
        end
    end

    # Followed link in user account confirmation email.
    # If you change this, change ApplicationController.test_code_redirect_by_email_token also
    def confirm
        post_redirect = PostRedirect.find_by_email_token(params[:email_token])

        if post_redirect.nil?
            render :template => 'user/bad_token.rhtml'
            return
        end

        @user = post_redirect.user
        @user.email_confirmed = true
        @user.save!

        session[:user_id] = @user.id
        session[:user_circumstance] = post_redirect.circumstance

        do_post_redirect post_redirect
    end

    # Logout form
    def signout
        session[:user_id] = nil
        session[:user_circumstance] = nil
        session[:remember_me] = false
        if params[:r]
            redirect_to params[:r]
        else
            redirect_to :controller => "general", :action => "index"
        end
    end

    # Change password (XXX and perhaps later email) - requires email authentication
    def signchange
        if @user and ((not session[:user_circumstance]) or (session[:user_circumstance] != "change_password"))
            # Not logged in via email, so send confirmation
            params[:submitted_signchange_send_confirm] = true
            params[:signchange] = { :email => @user.email }
        end

        if params[:submitted_signchange_send_confirm]
            # They've entered the email, check it is OK and user exists
            if not MySociety::Validate.is_valid_email(params[:signchange][:email])
                flash[:error] = "That doesn't look like a valid email address. Please check you have typed it correctly."
                render :action => 'signchange_send_confirm'
                return
            end
            user_signchange = User.find_user_by_email(params[:signchange][:email])
            if user_signchange
                # Send email with login link to go to signchange page
                url = signchange_url
                if params[:pretoken]
                    url += "?pretoken=" + params[:pretoken]
                end
                post_redirect = PostRedirect.new(:uri => url , :post_params => {},
                    :reason_params => {
                        :web => "",
                        :email => "Then you can change your password on WhatDoTheyKnow.com",
                        :email_subject => "Change your password on WhatDoTheyKnow.com"
                    },
                    :circumstance => "change_password" # special login that lets you change your password
                )
                post_redirect.user = user_signchange
                post_redirect.save!
                url = confirm_url(:email_token => post_redirect.email_token)
                UserMailer.deliver_confirm_login(user_signchange, post_redirect.reason_params, url)
            else
                # User not found, but still show confirm page to not leak fact user exists
            end

            render :action => 'signchange_confirm'
        elsif not @user
            # Not logged in, prompt for email
            render :action => 'signchange_send_confirm'
        else
            # Logged in via special email change password link, so can offer form to change password
            raise "internal error" unless (session[:user_circumstance] == "change_password")

            if params[:submitted_signchange_password]
                @user.password = params[:user][:password]
                @user.password_confirmation = params[:user][:password_confirmation]
                if not @user.valid?
                    render :action => 'signchange'
                else
                    @user.save!
                    flash[:notice] = "Your password has been changed."
                    if params[:pretoken] and not params[:pretoken].empty?
                        post_redirect = PostRedirect.find_by_token(params[:pretoken])
                        do_post_redirect post_redirect
                    else    
                        redirect_to user_url(@user)
                    end
                end
            else
                render :action => 'signchange'
            end
        end
    end

    # Send a message to another user
    def contact
        @recipient_user = User.find(params[:id])

        # Banned from messaging users?
        if !authenticated_user.nil? && !authenticated_user.can_contact_other_users?
            @details = authenticated_user.can_fail_html
            render :template => 'user/banned'
            return
        end

        # You *must* be logged into send a message to another user. (This is
        # partly to avoid spam, and partly to have some equanimity of openess
        # between the two users)
        if not authenticated?(
                :web => "To send a message to " + CGI.escapeHTML(@recipient_user.name),
                :email => "Then you can send a message to " + @recipient_user.name + ".",
                :email_subject => "Send a message to " + @recipient_user.name
            )
            # "authenticated?" has done the redirect to signin page for us
            return
        end

        if params[:submitted_contact_form]
            params[:contact][:name] = @user.name
            params[:contact][:email] = @user.email
            @contact = ContactValidator.new(params[:contact])
            if @contact.valid?
                ContactMailer.deliver_user_message(
                    @user,
                    @recipient_user,
                    main_url(user_url(@user)),
                    params[:contact][:subject],
                    params[:contact][:message]
                )
                flash[:notice] = "Your message to " + CGI.escapeHTML(@recipient_user.name) + " has been sent!"
                redirect_to user_url(@recipient_user)
                return
            end
        else
            @contact = ContactValidator.new(
                { :message => "" + @recipient_user.name + ",\n\n\n\nYours,\n\n" + @user.name }
            )
        end
  
    end

    # River of News: What's happening with your tracked things
    def river
        @results = @user.nil? ? [] : @user.track_things.collect { |thing|
          perform_search([InfoRequestEvent], thing.track_query, thing.params[:feed_sortby], nil).results
        }.flatten.sort { |a,b| b[:model].created_at <=> a[:model].created_at }.first(20)
    end

    private

    # Decide where we are going to redirect back to after signin/signup, and record that
    def work_out_post_redirect
        # Redirect to front page later if nothing else specified
        if not params[:r] and not params[:token]
            params[:r] = "/"  
        end
        # The explicit "signin" link uses this to specify where to go back to
        if params[:r]
            @post_redirect = PostRedirect.new(:uri => params[:r], :post_params => {},
                :reason_params => {
                    :web => "",
                    :email => "Then you can sign in to WhatDoTheyKnow.com",
                    :email_subject => "Confirm your account on WhatDoTheyKnow.com"
                })
            @post_redirect.save!
            params[:token] = @post_redirect.token
        elsif params[:token]
            # Otherwise we have a token (which represents a saved POST request)
            @post_redirect = PostRedirect.find_by_token(params[:token])
        end
    end

    # Ask for email confirmation
    def send_confirmation_mail(user)
        post_redirect = PostRedirect.find_by_token(params[:token])
        post_redirect.user = user
        post_redirect.save!

        url = confirm_url(:email_token => post_redirect.email_token)
        UserMailer.deliver_confirm_login(user, post_redirect.reason_params, url)
        render :action => 'confirm'
    end

    # If they register again
    def already_registered_mail(user)
        post_redirect = PostRedirect.find_by_token(params[:token])
        post_redirect.user = user
        post_redirect.save!

        url = confirm_url(:email_token => post_redirect.email_token)
        UserMailer.deliver_already_registered(user, post_redirect.reason_params, url)
        render :action => 'confirm' # must be same as for send_confirmation_mail above to avoid leak of presence of email in db
    end

    def set_profile_photo
        @photo_user = User.find(params[:id])
        new_profile_photo = ProfilePhoto.new(:data => data)
        @photo_user.set_profile_photo(new_profile_photo)
    end
end

