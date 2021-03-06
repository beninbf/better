require 'spec_helper'

describe NotificationsController, '#update' do

  let(:notification) { Factory.create(:notification) }
  let(:valid_params) { { :id => notification.id } }

  it 'assigns @notification' do
    put(:update, valid_params)
    assigns(:notification).should == notification
  end

  context 'when the notification successfully updates' do
    it 'responds with html' do
      put(:update, valid_params)
      response.should redirect_to(notification)
    end

    it 'responds with xml' do
      put(:update, valid_params.merge(:format => 'xml'))
      response.status.should == '200 OK'
    end
  end

  context 'when the notification does not successfully update' do
    let(:bad_notification) { Factory.create(:notification) }

    before(:each) do
      bad_notification.stub(:valid?).and_return(false)
      bad_notification.errors.add(:wat, 'an error')
      Notification.stub(:find).and_return(bad_notification)
    end

    it 'responds with html' do
      put(:update, valid_params)
      response.should render_template('notifications/edit')
    end

    it 'responds with xml' do
      put(:update, valid_params.merge(:format => 'xml'))
      response.body.should == bad_notification.errors.to_xml
      response.status.should == '422 Unprocessable Entity'
    end
  end

end
