class ContactsController < HumanController
  
  def index
    @contacts = Contact.all
  end
  
  def autocomplete
    term = params[:term]
    @contacts = Contact.find(:all, :conditions => ['login like ?', "%#{term}%"])
    output = @contacts.collect { |c| { :name => c.login } }

    respond_to do |format|
      format.json do
        render :json => output.to_json
      end
    end
  end
  
end
