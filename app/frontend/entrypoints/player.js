import { createApp } from 'vue'
import App from '../components/Screen.vue'

const div = document.getElementById('screen');
const screenId = parseInt(div.dataset.id);

createApp(App, {screenId: screenId}).mount(div);
