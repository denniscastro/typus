module AdminFormHelper

  ##
  # All helpers related to form.
  #

  def build_form(fields)
    returning(String.new) do |html|
      html << "#{error_messages_for :item, :header_tag => "h3"}"
      html << "<ul>"
      fields.each do |key, value|
        case value
        when :boolean:         html << typus_boolean_field(key, value)
        when :time:            html << typus_time_field(key, value)
        when :datetime:        html << typus_datetime_field(key, value)
        when :date:            html << typus_date_field(key, value)
        when :text:            html << typus_text_field(key, value)
        when :file:            html << typus_file_field(key, value)
        when :password:        html << typus_password_field(key, value)
        when :selector:        html << typus_selector_field(key, value)
        when :belongs_to:      html << typus_belongs_to_field(key, value)
        when :tree:            html << typus_tree_field(key, value)
        else
          html << typus_string_field(key, value)
        end
      end
      html << "</ul>"
    end
  end

  def typus_tree_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>
<select id="item_#{attribute}" name="item[#{attribute}]" <%= attribute_disabled?(attribute) ? 'disabled="disabled"' : '' %>>>
  <option value=""></option>
  #{expand_tree_into_select_field(@item.class.top)}
</select></li>
      HTML
    end
  end

  def typus_datetime_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{datetime_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }, {:disabled => attribute_disabled?(attribute)}}</li>
      HTML
    end
  end

  def typus_date_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{date_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }, {:disabled => attribute_disabled?(attribute)}}</li>
      HTML
    end
  end

  def typus_time_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{time_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }, {:disabled => attribute_disabled?(attribute)}}</li>
      HTML
    end
  end

  def typus_text_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{text_area :item, attribute, :class => 'text', :rows => Typus::Configuration.options[:form_rows], :disabled => attribute_disabled?(attribute)}</li>
      HTML
    end
  end

  def typus_selector_field(attribute, value)
    returning(String.new) do |html|
      options = ""
      @resource[:class].send(attribute).each do |option|
        case option.kind_of?(Array)
        when true
          options << <<-HTML
<option #{'selected' if @item.send(attribute).to_s == option.last.to_s} value="#{option.last}">#{option.first}</option>
          HTML
        else
          options << <<-HTML
<option #{'selected' if @item.send(attribute).to_s == option.to_s} value="#{option}">#{option}</option>
          HTML
        end
      end
      html << <<-HTML
<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>
<select id="item_#{attribute}" name="item[#{attribute}]" <%= attribute_disabled?(attribute) ? 'disabled="disabled"' : '' %>>
  <option value=""></option>
  #{options}
</select></li>
      HTML
    end
  end

  def typus_belongs_to_field(attribute, value)

    ##
    # We only can pass parameters to 'new' and 'edit', so this hack makes
    # the work to replace the current action.
    #
    params[:action] = (params[:action] == 'create') ? 'new' : params[:action]
    back_to = "/" + ([] << params[:controller] << params[:id] << params[:action]).compact.join('/')

    related = @resource[:class].reflect_on_association(attribute.to_sym).class_name.constantize
    related_fk = @resource[:class].reflect_on_association(attribute.to_sym).primary_key_name

    message = []
    message << "Are you sure you want to leave this page?"
    message << "If you have made any changes to the fields without clicking the Save/Update entry button, your changes will be lost."
    message << "Click OK to continue, or click Cancel to stay on this page."

    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{related_fk.humanize}
    <small>#{link_to t("Add new"), { :controller => attribute.tableize, :action => 'new', :back_to => back_to, :selected => related_fk }, :confirm => message.join("\n\n") if @current_user.can_perform?(related, 'create')}</small>
    </label>
#{select :item, related_fk, related.find(:all, :order => related.typus_order_by).collect { |p| [p.typus_name, p.id] }, { :include_blank => true }, { :disabled => attribute_disabled?(attribute) } }</li>
      HTML
    end

  end

  def typus_string_field(attribute, value)

    # Read only fields.
    if @resource[:class].typus_field_options_for(:read_only).include?(attribute)
      value = 'read_only' if %w( edit ).include?(params[:action])
    end

    # Auto generated fields.
    if @resource[:class].typus_field_options_for(:auto_generated).include?(attribute)
      value = 'auto_generated' if %w( new edit ).include?(params[:action])
    end

    comment = %w( read_only auto_generated ).include?(value) ? (value + " field").titleize : ""

    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize} <small>#{comment}</small></label>
#{text_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute) }</li>
      HTML
    end

  end

  def typus_password_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{password_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute)}</li>
      HTML
    end
  end

  def typus_boolean_field(attribute, value)

    question = true if @resource[:class].typus_field_options_for(:questions).include?(attribute)

    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}#{'?' if question}</label>
#{check_box :item, attribute} Checked if active</li>
      HTML
    end

  end

  def typus_file_field(attribute, value)

    attribute_display = attribute.split("_file_name").first
    content_type = @item.send("#{attribute_display}_content_type")

    returning(String.new) do |html|

      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_display.titleize.capitalize}</label>
      HTML

      case content_type
      when /image/
        html << "#{link_to image_tag(@item.send(attribute_display).url(:thumb)), @item.send(attribute_display).url, :style => "border: 1px solid #D3D3D3;"}<br /><br />"
      when /pdf|flv|quicktime/
        html << "<p>No preview available. (#{content_type.split('/').last})</p>"
      end

      html << "#{file_field :item, attribute.split("_file_name").first, :disabled => attribute_disabled?(attribute)}</li>"

    end

  end

  def typus_relationships

    @back_to = "/" + ([] << params[:controller] << params[:id]<< params[:action]).compact.join('/')

    returning(String.new) do |html|
      @item_relationships.each do |relationship|
        case @resource[:class].reflect_on_association(relationship.to_sym).macro
        when :has_many
          html << typus_form_has_many(relationship)
        when :has_and_belongs_to_many
          html << typus_form_has_and_belongs_to_many(relationship)
        end
      end
    end

  end

  def typus_form_has_many(field)
    returning(String.new) do |html|
      model_to_relate = field.classify.constantize
      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to field.titleize, :controller => field}
  <small>#{link_to t("Add new"), :controller => field, :action => 'new', :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id if @current_user.can_perform?(model_to_relate, 'create')}</small>
  </h2>
      HTML
      items = @resource[:class].find(params[:id]).send(field)
      unless items.empty?
        html << build_table(model_to_relate, model_to_relate.typus_fields_for(:relationship), items)
      else
        html << <<-HTML
<div id="flash" class="notice"><p>#{t("There are no {{records}}.", :records => field.titleize.downcase)}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def typus_form_has_and_belongs_to_many(field)
    returning(String.new) do |html|
      model_to_relate = field.classify.constantize
      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to field.titleize, :controller => field}
  <small>#{link_to t("Add new"), :controller => field, :action => 'new', :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id if @current_user.can_perform?(model_to_relate, 'create')}</small>
  </h2>
      HTML
      items_to_relate = (model_to_relate.find(:all) - @item.send(field))
      unless items_to_relate.empty?
        html << <<-HTML
  #{form_tag :action => 'relate'}
  #{hidden_field :related, :model, :value => model_to_relate}
  <p>#{ select :related, :id, items_to_relate.collect { |f| [f.typus_name, f.id] }.sort_by { |e| e.first } } &nbsp; #{submit_tag "Add", :class => 'button'}</p>
  </form>
        HTML
      end
      items = @resource[:class].find(params[:id]).send(field)
      unless items.empty?
        html << build_table(model_to_relate, model_to_relate.typus_fields_for(:relationship), items)
      else
        html << <<-HTML
  <div id="flash" class="notice"><p>#{t("There are no {{records}}.", :records => field.titleize.downcase)}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def attribute_disabled?(attribute)
    if @resource[:class].accessible_attributes.nil?
      return false
    else
      return !@resource[:class].accessible_attributes.include?(attribute)
    end
  end

  ##
  # Tree when +acts_as_tree+
  #
  def expand_tree_into_select_field(categories)
    returning(String.new) do |html|
      categories.each do |category|
        html << %{<option #{"selected" if @item.parent_id == category.id} value="#{category.id}">#{"-" * category.ancestors.size} #{category.name}</option>}
        html << expand_tree_into_select_field(category.children) if category.has_children?
      end
    end
  end

end